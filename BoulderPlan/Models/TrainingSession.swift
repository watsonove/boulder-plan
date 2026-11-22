import Foundation
import SwiftData

/// Eine geplante Trainingseinheit an einem bestimmten Tag.
@Model
final class TrainingSession {
    var id: UUID = UUID()
    /// Tag der Session (immer Tagesbeginn).
    var date: Date = Date()
    /// Ursprünglich geplanter Tag (vor Verschieben/Pausieren).
    var originalDate: Date = Date()
    /// Planwoche 1–12.
    var week: Int = 1
    /// Phasen-ID aus der Seed-Datei (base, deload, max, power, test).
    var phaseId: String = ""
    var typeRaw: String = "A"
    var title: String = ""
    /// Optionale Sessions (Mobility an freien Tagen) zählen nicht in Statistik/Streak.
    var isOptional: Bool = false
    var isSkipped: Bool = false
    /// Leichte Variante nach Check-in: −1 Satz, keine Limit-Versuche.
    var lightMode: Bool = false
    /// „Wenig Zeit“: nur Kernübungen in Kurzform (~45 min).
    var quickMode: Bool = false
    var wasMoved: Bool = false
    /// Übungen wurden bearbeitet/getauscht/hinzugefügt.
    var contentEdited: Bool = false
    var checkInSleep: Int? = nil
    var checkInEnergy: Int? = nil
    var checkInFingers: Int? = nil
    var completedAt: Date? = nil
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    init(date: Date, week: Int, phaseId: String, type: SessionType, title: String, isOptional: Bool) {
        self.id = UUID()
        self.date = date.startOfDay
        self.originalDate = date.startOfDay
        self.week = week
        self.phaseId = phaseId
        self.typeRaw = type.rawValue
        self.title = title
        self.isOptional = isOptional
    }
}

// MARK: - Abgeleitete Werte

extension TrainingSession {
    var type: SessionType { SessionType(rawValue: typeRaw) ?? .A }

    var sortedExercises: [SessionExercise] {
        exercises.sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Übungen, die im aktuellen Modus angezeigt werden.
    var visibleExercises: [SessionExercise] {
        sortedExercises.filter(isVisible)
    }

    func isVisible(_ exercise: SessionExercise) -> Bool {
        if quickMode && !exercise.isCore { return false }
        if lightMode && exercise.isLimit { return false }
        return true
    }

    /// Übungen, die für „erledigt“ abgehakt sein müssen (Kernübungen).
    /// Hat eine Session keine Kernübungen, zählen alle sichtbaren.
    var requiredExercises: [SessionExercise] {
        let visible = visibleExercises
        let core = visible.filter(\.isCore)
        return core.isEmpty ? visible : core
    }

    var completedRequiredCount: Int {
        requiredExercises.filter(\.isCompleted).count
    }

    /// Fortschritt 0…1 über alle sichtbaren Übungen (Sätze anteilig).
    var progress: Double {
        let visible = visibleExercises
        guard !visible.isEmpty else { return 0 }
        return visible.map(\.progress).reduce(0, +) / Double(visible.count)
    }

    /// Erledigt, sobald alle Kernübungen abgehakt sind.
    var isDone: Bool {
        let required = requiredExercises
        return !required.isEmpty && required.allSatisfy(\.isCompleted)
    }

    var status: SessionStatus {
        if isSkipped { return .skipped }
        if isDone { return .done }
        if progress > 0 { return .partial }
        return .open
    }

    /// Wurde an der Session schon etwas gemacht? (Schutz beim Neu-Erstellen des Plans)
    var hasProgress: Bool {
        isSkipped || contentEdited || checkInSleep != nil
            || exercises.contains { $0.isCompleted || $0.completedSets.contains(true) }
    }

    var estimatedMinutes: Int {
        visibleExercises.reduce(0) { $0 + $1.effectiveMinutes }
    }

    var hasCheckIn: Bool { checkInSleep != nil }

    var checkInSummary: String? {
        guard let s = checkInSleep, let e = checkInEnergy, let f = checkInFingers else { return nil }
        return "Check-in: Schlaf \(s) · Energie \(e) · Finger \(f)"
    }

    /// Vergangene, nicht begonnene Pflicht-Session.
    var isMissed: Bool {
        !isOptional && status == .open && date.startOfDay < Date().startOfDay
    }

    /// Setzt bzw. löscht den Abschlusszeitpunkt passend zum Status.
    func refreshCompletionDate() {
        if isDone {
            if completedAt == nil { completedAt = .now }
        } else {
            completedAt = nil
        }
    }

    /// Nach Moduswechsel Abschluss pro Übung neu berechnen (Satzanzahl ändert sich).
    func syncExerciseCompletion() {
        exercises.forEach { $0.syncCompletion() }
        refreshCompletionDate()
    }
}
