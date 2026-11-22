import Foundation
import SwiftData

/// Ergebnis einer Prüfung vor dem Verschieben.
enum MoveCheck {
    case ok
    /// Ziel liegt außerhalb der Trainingswoche der Session.
    case outsideWeek
    /// Weniger als 48 h zu anderen fingerintensiven Sessions.
    case fingerConflict([TrainingSession])
}

/// Alle Operationen rund um den Terminplan: Verschieben, Pausieren, Nachholen, Neu-Erstellen.
enum ScheduleService {

    // MARK: - Fetch

    static func fetchSettings(_ context: ModelContext) -> AppSettings? {
        (try? context.fetch(FetchDescriptor<AppSettings>()))?.first
    }

    static func fetchSessions(_ context: ModelContext) -> [TrainingSession] {
        let descriptor = FetchDescriptor<TrainingSession>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Aktuelle Woche

    /// Aktuelle Planwoche: Woche der heutigen bzw. nächsten offenen Session.
    /// 0 = noch keine Sessions, totalWeeks + 1 = Plan abgeschlossen.
    static func currentWeek(sessions: [TrainingSession], settings: AppSettings?, today: Date = .now) -> Int {
        let day = today.startOfDay
        let main = sessions.filter { !$0.isOptional }
        if let todays = main.first(where: { $0.date.isSameDay(as: day) }) {
            return todays.week
        }
        if let next = main.filter({ $0.date > day && !$0.isSkipped && !$0.isDone }).min(by: { $0.date < $1.date }) {
            return next.week
        }
        if main.isEmpty, let settings {
            let diff = PlanGenerator.weekStart(1, settings: settings).days(to: day)
            return diff < 0 ? 1 : min(diff / 7 + 1, PlanRepository.shared.totalWeeks + 1)
        }
        return PlanRepository.shared.totalWeeks + 1
    }

    // MARK: - 48-h-Regel

    /// Fingerintensive Sessions (A, C), die weniger als 48 h vom Zieltag entfernt liegen.
    static func fingerConflicts(for session: TrainingSession, on date: Date, among all: [TrainingSession]) -> [TrainingSession] {
        guard session.type.isFingerIntensive else { return [] }
        return all.filter { other in
            other.id != session.id
                && other.type.isFingerIntensive
                && !other.isSkipped
                && abs(other.date.days(to: date)) < 2
        }
    }

    // MARK: - Verschieben

    static func checkMove(_ session: TrainingSession, to date: Date, among all: [TrainingSession], settings: AppSettings?) -> MoveCheck {
        if let settings {
            let days = PlanGenerator.weekDates(session.week, settings: settings)
            if let first = days.first, let last = days.last {
                let target = date.startOfDay
                if target < first || target > last { return .outsideWeek }
            }
        }
        let conflicts = fingerConflicts(for: session, on: date, among: all)
        return conflicts.isEmpty ? .ok : .fingerConflict(conflicts)
    }

    static func move(_ session: TrainingSession, to date: Date, context: ModelContext) {
        session.date = date.startOfDay
        session.wasMoved = true
        didChangeSchedule(context)
    }

    // MARK: - Krank / Urlaub

    /// Verschiebt alle noch nicht erledigten Sessions ab heute um `days` Tage.
    static func pause(days: Int, settings: AppSettings, context: ModelContext) {
        let today = Date().startOfDay
        for session in fetchSessions(context) where session.date >= today && !session.isDone {
            session.date = session.date.adding(days: days)
        }
        settings.shiftDays += days
        didChangeSchedule(context)
    }

    /// Markiert alle offenen Sessions einer Woche als übersprungen.
    static func skipWeek(_ week: Int, context: ModelContext) {
        for session in fetchSessions(context) where session.week == week && !session.isDone {
            session.isSkipped = true
        }
        didChangeSchedule(context)
    }

    // MARK: - Nachholen

    /// Nächster Tag ab `start` ohne andere Pflicht-Session und ohne 48-h-Konflikt.
    static func nextFreeDay(for session: TrainingSession, among all: [TrainingSession], from start: Date = .now) -> Date? {
        let first = start.startOfDay
        for offset in 0..<21 {
            let day = first.adding(days: offset)
            let occupied = all.contains {
                $0.id != session.id && !$0.isOptional && !$0.isSkipped && $0.date.isSameDay(as: day)
            }
            if occupied { continue }
            if !fingerConflicts(for: session, on: day, among: all).isEmpty { continue }
            return day
        }
        return nil
    }

    /// Legt eine (verpasste) Session in die nächste freie Lücke. Gibt den neuen Tag zurück.
    @discardableResult
    static func makeUp(_ session: TrainingSession, among all: [TrainingSession], context: ModelContext) -> Date? {
        guard let day = nextFreeDay(for: session, among: all) else { return nil }
        session.date = day
        session.wasMoved = true
        session.isSkipped = false
        didChangeSchedule(context)
        return day
    }

    // MARK: - Plan neu erstellen

    /// Erstellt zukünftige, noch unberührte Sessions neu (nach Änderung der Einstellungen).
    /// Sessions mit Fortschritt sowie alle vergangenen Sessions bleiben erhalten.
    static func rebuildFuture(context: ModelContext, settings: AppSettings) {
        let today = Date().startOfDay
        let all = fetchSessions(context)
        let fromWeek = max(1, currentWeek(sessions: all, settings: settings))

        let removable = all.filter { $0.date >= today && !$0.hasProgress }
        let removableIDs = Set(removable.map(\.id))
        removable.forEach { context.delete($0) }
        let remaining = all.filter { !removableIDs.contains($0.id) }

        let generator = PlanGenerator()
        for blueprint in generator.blueprints(for: settings) where blueprint.date >= today && blueprint.week >= fromWeek {
            let exists = remaining.contains { session in
                session.week == blueprint.week && session.type == blueprint.type
                    && (blueprint.type != .E || session.date.isSameDay(as: blueprint.date))
            }
            if !exists {
                generator.insertSession(blueprint, hasHangboard: settings.hasHangboard, into: context)
            }
        }
        didChangeSchedule(context)
    }

    /// Löscht alle Sessions und erstellt den Plan komplett neu (Benchmarks bleiben erhalten).
    static func regenerateAll(context: ModelContext, settings: AppSettings) {
        fetchSessions(context).forEach { context.delete($0) }
        settings.shiftDays = 0
        let generator = PlanGenerator()
        for blueprint in generator.blueprints(for: settings) {
            generator.insertSession(blueprint, hasHangboard: settings.hasHangboard, into: context)
        }
        didChangeSchedule(context)
    }

    /// Speichern + Erinnerungen neu planen.
    static func didChangeSchedule(_ context: ModelContext) {
        try? context.save()
        NotificationService.reschedule(context: context)
    }
}
