import Foundation
import Observation
import SwiftData

/// Entwurf für das Bearbeiten bzw. Anlegen einer Übung.
struct ExerciseDraft {
    var name = ""
    var info = ""
    var sets = 3
    var reps = "8"
    var restSeconds = 120
    var intensity = ""
    var hasWeight = false
    var weightKg: Double = 0
    var minutes = 10
    var isCore = false
    var notes = ""

    init() {}

    init(_ e: SessionExercise) {
        name = e.name
        info = e.info
        sets = e.sets
        reps = e.reps
        restSeconds = e.restSeconds
        intensity = e.intensity
        hasWeight = e.weightKg != nil
        weightKg = e.weightKg ?? 0
        minutes = e.minutes
        isCore = e.isCore
        notes = e.notes
    }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func apply(to e: SessionExercise) {
        e.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        e.info = info
        e.reps = reps
        e.restSeconds = restSeconds
        e.intensity = intensity
        e.weightKg = hasWeight ? weightKg : nil
        e.minutes = minutes
        e.isCore = isCore
        e.notes = notes
        if e.sets != sets {
            e.sets = sets
            e.resizeSets()
        }
    }
}

/// Logik für eine einzelne Session: Abhaken, Modi, Check-in, Bearbeiten, Verschieben.
@Observable
final class SessionViewModel {

    // MARK: - Abhaken

    func toggle(_ exercise: SessionExercise, in session: TrainingSession, context: ModelContext) {
        let wasDone = session.isDone
        exercise.toggleCompleted()
        if exercise.isCompleted { Haptics.tap() } else { Haptics.selection() }
        finishProgressChange(session, wasDone: wasDone, context: context)
    }

    func toggleSet(_ index: Int, of exercise: SessionExercise, in session: TrainingSession, context: ModelContext) {
        let wasDone = session.isDone
        exercise.toggleSet(index)
        Haptics.tap()
        finishProgressChange(session, wasDone: wasDone, context: context)
    }

    private func finishProgressChange(_ session: TrainingSession, wasDone: Bool, context: ModelContext) {
        session.refreshCompletionDate()
        if session.isDone && !wasDone { Haptics.success() }
        save(context)
        // Erledigte Sessions brauchen keine Erinnerung mehr.
        if wasDone != session.isDone { NotificationService.reschedule(context: context) }
    }

    // MARK: - Modi

    func toggleQuickMode(_ session: TrainingSession, context: ModelContext) {
        session.quickMode.toggle()
        session.syncExerciseCompletion()
        save(context)
    }

    func toggleLightMode(_ session: TrainingSession, context: ModelContext) {
        session.lightMode.toggle()
        session.syncExerciseCompletion()
        save(context)
    }

    /// Speichert den Check-in und aktiviert ggf. die leichte Variante.
    func applyCheckIn(_ session: TrainingSession, sleep: Int, energy: Int, fingers: Int, useLight: Bool, context: ModelContext) {
        session.checkInSleep = sleep
        session.checkInEnergy = energy
        session.checkInFingers = fingers
        session.lightMode = useLight
        session.syncExerciseCompletion()
        save(context)
        Haptics.success()
    }

    // MARK: - Status

    func setSkipped(_ skipped: Bool, _ session: TrainingSession, context: ModelContext) {
        session.isSkipped = skipped
        if skipped { Haptics.warning() } else { Haptics.success() }
        ScheduleService.didChangeSchedule(context)
    }

    func resetProgress(_ session: TrainingSession, context: ModelContext) {
        for exercise in session.exercises {
            exercise.isCompleted = false
            exercise.completedSets = Array(repeating: false, count: max(exercise.sets, 1))
        }
        session.checkInSleep = nil
        session.checkInEnergy = nil
        session.checkInFingers = nil
        session.lightMode = false
        session.quickMode = false
        session.isSkipped = false
        session.completedAt = nil
        ScheduleService.didChangeSchedule(context)
    }

    // MARK: - Termin

    func move(_ session: TrainingSession, to date: Date, context: ModelContext) {
        ScheduleService.move(session, to: date, context: context)
        Haptics.success()
    }

    func makeUp(_ session: TrainingSession, all: [TrainingSession], context: ModelContext) -> Date? {
        let day = ScheduleService.makeUp(session, among: all, context: context)
        if day != nil { Haptics.success() } else { Haptics.warning() }
        return day
    }

    // MARK: - Übungen bearbeiten

    /// Tauscht eine Übung gegen eine andere aus der Bibliothek (z. B. Kilter ↔ Moonboard).
    /// Sätze, Pause und Gewicht bleiben, die alte Übung wird zur Alternative.
    func swap(_ exercise: SessionExercise, toKey key: String, context: ModelContext) {
        let repo = PlanRepository.shared
        guard let library = repo.exercise(key) else { return }
        var alternatives = Set(exercise.alternatives)
        alternatives.insert(exercise.key)
        alternatives.formUnion(library.alternatives ?? [])
        alternatives.remove(key)
        exercise.alternatives = alternatives.filter { repo.exercise($0) != nil }.sorted()

        exercise.key = key
        exercise.name = library.name
        exercise.info = library.description
        exercise.category = library.category
        if let reps = library.defaultReps { exercise.reps = reps }
        if let intensity = library.defaultIntensity { exercise.intensity = intensity }
        exercise.isCompleted = false
        exercise.completedSets = Array(repeating: false, count: max(exercise.sets, 1))
        exercise.session?.contentEdited = true
        exercise.session?.refreshCompletionDate()
        save(context)
        Haptics.success()
    }

    func save(_ draft: ExerciseDraft, to exercise: SessionExercise, context: ModelContext) {
        draft.apply(to: exercise)
        exercise.session?.contentEdited = true
        exercise.session?.refreshCompletionDate()
        save(context)
    }

    func addCustom(_ draft: ExerciseDraft, to session: TrainingSession, context: ModelContext) {
        let exercise = SessionExercise(key: "custom-\(UUID().uuidString)", name: "", info: "", category: "custom")
        draft.apply(to: exercise)
        exercise.sets = draft.sets
        exercise.completedSets = Array(repeating: false, count: max(draft.sets, 1))
        exercise.isCustom = true
        exercise.sortIndex = (session.exercises.map(\.sortIndex).max() ?? 0) + 1
        context.insert(exercise)
        exercise.session = session
        session.contentEdited = true
        session.refreshCompletionDate()
        save(context)
        Haptics.success()
    }

    func delete(_ exercise: SessionExercise, from session: TrainingSession, context: ModelContext) {
        session.exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)
        session.contentEdited = true
        session.refreshCompletionDate()
        save(context)
    }

    private func save(_ context: ModelContext) {
        try? context.save()
    }
}
