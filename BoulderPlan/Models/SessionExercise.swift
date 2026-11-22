import Foundation
import SwiftData

/// Eine Übung innerhalb einer Session – mit Vorgabe, Abhak-Status und Notiz.
@Model
final class SessionExercise {
    var id: UUID = UUID()
    /// Reihenfolge innerhalb der Session.
    var sortIndex: Int = 0
    /// Schlüssel in der Übungsbibliothek (bei eigenen Übungen "custom-…").
    var key: String = ""
    var name: String = ""
    /// Beschreibung/Ausführungshinweise.
    var info: String = ""
    var category: String = ""
    var sets: Int = 1
    /// Wiederholungen bzw. Dauer als Text, z. B. "8–10" oder "10 s".
    var reps: String = ""
    var restSeconds: Int = 0
    /// Intensität als Text: Grad, RPE oder Zusatzgewicht-Spanne.
    var intensity: String = ""
    /// Konkretes Arbeitsgewicht (optional, vom Nutzer gepflegt).
    var weightKg: Double? = nil
    var minutes: Int = 10
    var isCore: Bool = false
    var isLimit: Bool = false
    var benchmarkRaw: String? = nil
    /// Austauschübungen (Bibliotheksschlüssel), z. B. Kilter ↔ Moonboard.
    var alternatives: [String] = []
    var notes: String = ""
    var isCompleted: Bool = false
    /// Abhak-Status je Satz.
    var completedSets: [Bool] = []
    var isCustom: Bool = false
    /// Kurzform für den „Wenig Zeit“-Modus.
    var quickSets: Int? = nil
    var quickReps: String? = nil
    var quickMinutes: Int? = nil

    var session: TrainingSession?

    init(key: String, name: String, info: String, category: String) {
        self.id = UUID()
        self.key = key
        self.name = name
        self.info = info
        self.category = category
    }
}

// MARK: - Logik

extension SessionExercise {
    var benchmark: BenchmarkKind? { benchmarkRaw.flatMap(BenchmarkKind.init(rawValue:)) }

    private var inQuickMode: Bool { session?.quickMode ?? false }
    private var inLightMode: Bool { session?.lightMode ?? false }

    /// Geplante Sätze im aktuellen Modus (Wenig Zeit nutzt die Kurzform).
    var plannedSets: Int {
        inQuickMode ? min(quickSets ?? sets, sets) : sets
    }

    /// Tatsächlich zu absolvierende Sätze (leichte Variante: −1 Satz).
    var effectiveSets: Int {
        let base = max(1, plannedSets)
        return inLightMode && base > 1 ? base - 1 : base
    }

    var effectiveReps: String { inQuickMode ? (quickReps ?? reps) : reps }
    var effectiveMinutes: Int { inQuickMode ? (quickMinutes ?? minutes) : minutes }

    func isSetDone(_ index: Int) -> Bool {
        completedSets.indices.contains(index) && completedSets[index]
    }

    var doneSetCount: Int {
        isCompleted ? effectiveSets : completedSets.prefix(effectiveSets).filter { $0 }.count
    }

    var progress: Double {
        isCompleted ? 1 : Double(doneSetCount) / Double(max(1, effectiveSets))
    }

    /// Ganze Übung abhaken/zurücksetzen – setzt alle Sätze mit.
    func toggleCompleted() {
        let newValue = !isCompleted
        isCompleted = newValue
        completedSets = Array(repeating: newValue, count: max(sets, 1))
    }

    /// Einzelnen Satz abhaken. Sind alle effektiven Sätze erledigt, ist die Übung erledigt.
    func toggleSet(_ index: Int) {
        var flags = completedSets
        if flags.count < sets { flags += Array(repeating: false, count: sets - flags.count) }
        guard flags.indices.contains(index) else { return }
        flags[index].toggle()
        completedSets = flags
        isCompleted = flags.prefix(effectiveSets).allSatisfy { $0 }
    }

    /// Nach Moduswechsel prüfen, ob die (neue) Satzanzahl erfüllt ist.
    func syncCompletion() {
        guard !completedSets.isEmpty else { return }
        isCompleted = completedSets.prefix(effectiveSets).allSatisfy { $0 }
    }

    /// Satz-Array nach Änderung der Satzanzahl anpassen.
    func resizeSets() {
        if isCompleted {
            completedSets = Array(repeating: true, count: max(sets, 1))
            return
        }
        var flags = completedSets
        if flags.count < sets {
            flags += Array(repeating: false, count: sets - flags.count)
        } else {
            flags = Array(flags.prefix(sets))
        }
        completedSets = flags
    }

    /// Kompakte Vorgabe, z. B. "6 × 10 s · Pause 3 min · +15–20 kg · RPE 9".
    var prescriptionText: String {
        var parts: [String] = []
        let s = effectiveSets
        let r = effectiveReps
        if s > 1 {
            parts.append(r.isEmpty ? "\(s) Sätze" : "\(s) × \(r)")
        } else if !r.isEmpty {
            parts.append(r)
        }
        if restSeconds > 0 { parts.append("Pause \(RestFormatter.string(restSeconds))") }
        if !intensity.isEmpty { parts.append(intensity) }
        if let w = weightKg { parts.append((w > 0 ? "+" : "") + w.cleanString + " kg") }
        return parts.joined(separator: " · ")
    }
}
