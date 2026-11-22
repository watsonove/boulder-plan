import Foundation
import SwiftData

/// Bauplan einer Session, bevor sie in SwiftData angelegt wird.
struct SessionBlueprint {
    let date: Date
    let week: Int
    let phaseId: String
    let type: SessionType
    let isOptional: Bool
}

/// Erzeugt aus Seed-Daten + Einstellungen die konkreten Sessions mit Übungen.
struct PlanGenerator {
    private let repo = PlanRepository.shared

    // MARK: - Datumslogik

    /// Woche 1 beginnt immer am Montag der Woche des Startdatums.
    static func planStart(_ settings: AppSettings) -> Date {
        settings.startDate.mondayOfWeek
    }

    /// Erster Tag einer Planwoche (inkl. Pausen-Verschiebung).
    static func weekStart(_ week: Int, settings: AppSettings) -> Date {
        planStart(settings).adding(days: (week - 1) * 7 + settings.shiftDays)
    }

    /// Die 7 Tage einer Planwoche.
    static func weekDates(_ week: Int, settings: AppSettings) -> [Date] {
        let start = weekStart(week, settings: settings)
        return (0..<7).map { start.adding(days: $0) }
    }

    /// Gültige Wochentage – fällt auf die Standardtage zurück, wenn die Auswahl nicht passt.
    static func resolvedWeekdays(_ weekdays: [Int], daysPerWeek: Int) -> [Int] {
        let unique = Array(Set(weekdays.filter { (1...7).contains($0) })).sorted()
        if unique.count == daysPerWeek { return unique }
        return (PlanRepository.shared.layout(daysPerWeek: daysPerWeek)?.defaultWeekdays ?? [1, 2, 4, 6]).sorted()
    }

    /// Session-Typ für den n-ten Trainingstag einer Woche.
    static func sessionType(slotIndex: Int, week: Int, layout: WeekLayoutSeed) -> SessionType? {
        let slots = layout.weekOverrides?[String(week)] ?? layout.slots
        guard !slots.isEmpty else { return nil }
        let slot = slots[slotIndex % slots.count]
        guard !slot.isEmpty else { return nil }
        // Mehrere Typen in einem Slot (z. B. C/D bei 3 Tagen) wechseln wochenweise.
        return SessionType(rawValue: slot[(week - 1) % slot.count])
    }

    // MARK: - Blueprints

    /// Alle Sessions der 12 Wochen gemäß aktueller Einstellungen.
    func blueprints(for settings: AppSettings) -> [SessionBlueprint] {
        guard let layout = repo.layout(daysPerWeek: settings.daysPerWeek) else { return [] }
        let weekdays = Self.resolvedWeekdays(settings.weekdays, daysPerWeek: settings.daysPerWeek)
        var result: [SessionBlueprint] = []

        for info in repo.seed.weeks {
            let start = Self.weekStart(info.week, settings: settings)
            for (index, weekday) in weekdays.enumerated() {
                guard let type = Self.sessionType(slotIndex: index, week: info.week, layout: layout) else { continue }
                result.append(SessionBlueprint(date: start.adding(days: weekday - 1), week: info.week,
                                               phaseId: info.phase, type: type, isOptional: false))
            }
            // Optionale Mobility (E) an freien Tagen.
            if settings.showMobility {
                for weekday in 1...7 where !weekdays.contains(weekday) {
                    result.append(SessionBlueprint(date: start.adding(days: weekday - 1), week: info.week,
                                                   phaseId: info.phase, type: .E, isOptional: true))
                }
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    // MARK: - Sessions & Übungen anlegen

    /// Legt eine Session samt Übungen im Kontext an.
    @discardableResult
    func insertSession(_ blueprint: SessionBlueprint, hasHangboard: Bool, into context: ModelContext) -> TrainingSession {
        let session = TrainingSession(date: blueprint.date, week: blueprint.week, phaseId: blueprint.phaseId,
                                      type: blueprint.type, title: repo.title(for: blueprint.type),
                                      isOptional: blueprint.isOptional)
        context.insert(session)
        let exercises = makeExercises(type: blueprint.type, week: blueprint.week,
                                      phaseId: blueprint.phaseId, hasHangboard: hasHangboard)
        for exercise in exercises {
            context.insert(exercise)
            exercise.session = session
        }
        return session
    }

    /// Löst die Session-Vorlage für Woche/Phase auf (Filter, Phasen-Overrides, Hangboard-Ersatz).
    func makeExercises(type: SessionType, week: Int, phaseId: String, hasHangboard: Bool) -> [SessionExercise] {
        let entries = repo.seed.sessions[type.rawValue] ?? []
        var result: [SessionExercise] = []
        for entry in entries where Self.applies(entry, week: week, phaseId: phaseId) {
            var prescription = Prescription(entry: entry)
            if let override = entry.phases?[phaseId] { prescription.apply(override) }
            if !hasHangboard, let fallback = entry.noHangboard { prescription.apply(fallback) }
            result.append(makeExercise(prescription, benchmark: entry.benchmark, quick: entry.quick, index: result.count))
        }
        return result
    }

    static func applies(_ entry: SessionEntrySeed, week: Int, phaseId: String) -> Bool {
        if let only = entry.onlyPhases, !only.contains(phaseId) { return false }
        if let except = entry.exceptPhases, except.contains(phaseId) { return false }
        if let only = entry.onlyWeeks, !only.contains(week) { return false }
        if let except = entry.exceptWeeks, except.contains(week) { return false }
        return true
    }

    private func makeExercise(_ p: Prescription, benchmark: String?, quick: QuickSeed?, index: Int) -> SessionExercise {
        let library = repo.exercise(p.key)
        let exercise = SessionExercise(key: p.key, name: library?.name ?? p.key,
                                       info: library?.description ?? "", category: library?.category ?? "custom")
        exercise.sortIndex = index
        exercise.sets = max(1, p.sets)
        exercise.reps = p.reps
        exercise.restSeconds = p.rest
        exercise.intensity = p.intensity
        exercise.weightKg = p.weight
        exercise.minutes = p.minutes
        exercise.isCore = p.core
        exercise.isLimit = p.limit
        exercise.benchmarkRaw = benchmark
        exercise.alternatives = library?.alternatives ?? []
        exercise.quickSets = quick?.sets
        exercise.quickReps = quick?.reps
        exercise.quickMinutes = quick?.minutes
        exercise.completedSets = Array(repeating: false, count: exercise.sets)
        if !p.notes.isEmpty {
            exercise.info += (exercise.info.isEmpty ? "" : "\n\n") + "Hinweis: " + p.notes
        }
        return exercise
    }

    // MARK: - Vorschau & Warnungen für die Wochentagsauswahl

    /// z. B. "Mo: A · Di: B · Do: C · Sa: D"
    static func layoutPreview(weekdays: Set<Int>, daysPerWeek: Int) -> String {
        guard let layout = PlanRepository.shared.layout(daysPerWeek: daysPerWeek) else { return "" }
        let days = weekdays.sorted()
        guard days.count == daysPerWeek else { return "Bitte genau \(daysPerWeek) Tage wählen." }
        let parts: [String] = days.enumerated().map { item -> String in
            let slot = layout.slots[item.offset % layout.slots.count]
            return "\(Weekday.short(item.element)): \(slot.joined(separator: "/"))"
        }
        return parts.joined(separator: " · ")
    }

    /// Warnt, wenn fingerintensive Sessions (A, C) < 48 h auseinanderliegen würden.
    static func layoutWarnings(weekdays: Set<Int>, daysPerWeek: Int) -> [String] {
        guard let layout = PlanRepository.shared.layout(daysPerWeek: daysPerWeek),
              weekdays.count == daysPerWeek else { return [] }
        let days = weekdays.sorted()
        var fingerDays: [Int] = []
        for (index, weekday) in days.enumerated() {
            let slot = layout.slots[index % layout.slots.count]
            if slot.contains(where: { SessionType(rawValue: $0)?.isFingerIntensive == true }) {
                fingerDays.append(weekday)
            }
        }
        var warnings: [String] = []
        for i in fingerDays.indices {
            for j in fingerDays.indices where j > i {
                let diff = fingerDays[j] - fingerDays[i]
                let gap = min(diff, 7 - diff) // inkl. Übergang Sonntag → Montag
                if gap < 2 {
                    warnings.append("\(Weekday.short(fingerDays[i])) & \(Weekday.short(fingerDays[j])): fingerintensive Sessions mit weniger als 48 h Abstand.")
                }
            }
        }
        return warnings
    }
}
