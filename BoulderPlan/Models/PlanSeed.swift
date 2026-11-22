import Foundation

// MARK: - Seed-Datenmodell
//
// Diese Structs spiegeln exakt die Struktur von `Resources/plan_seed.json` wider.
// Der komplette Trainingsplan (Phasen, Wochen, Session-Inhalte, Übungsbibliothek)
// ist dort datengetrieben hinterlegt und kann ohne Swift-Änderungen angepasst werden.

/// Wurzelobjekt der Seed-Datei.
struct PlanSeed: Decodable {
    let version: Int
    let name: String
    /// Trainingsphasen (Basis, Deload, Maximalkraft, …).
    let phases: [PhaseSeed]
    /// Die 12 Wochen mit Zuordnung zur Phase und Wochenfokus.
    let weeks: [WeekSeed]
    /// Titel/Untertitel je Session-Typ ("A", "B", …).
    let sessionTypes: [String: SessionTypeSeed]
    /// Wochenaufteilung je Anzahl Trainingstage ("3", "4", "5").
    let weekLayouts: [String: WeekLayoutSeed]
    /// Übungsbibliothek, Schlüssel = Übungs-ID.
    let exercises: [String: ExerciseSeed]
    /// Session-Inhalte je Typ: geordnete Liste von Übungseinträgen.
    let sessions: [String: [SessionEntrySeed]]
}

struct PhaseSeed: Decodable, Identifiable {
    let id: String
    let name: String
    let color: String
    let description: String
}

struct WeekSeed: Decodable, Identifiable {
    let week: Int
    let phase: String
    let focus: String
    var id: Int { week }
}

struct SessionTypeSeed: Decodable {
    let title: String
    let subtitle: String
    let estimatedMinutes: Int
}

/// Aufteilung einer Woche: `slots[i]` gehört zum i-ten gewählten Wochentag.
/// Enthält ein Slot mehrere Typen (z. B. ["C", "D"]), wird wochenweise gewechselt.
struct WeekLayoutSeed: Decodable {
    let defaultWeekdays: [Int]
    let slots: [[String]]
    /// Optionale Abweichungen für einzelne Wochen (Schlüssel = Wochennummer).
    let weekOverrides: [String: [[String]]]?
}

/// Eintrag in der Übungsbibliothek.
struct ExerciseSeed: Decodable {
    let name: String
    let category: String
    let description: String
    let alternatives: [String]?
    let defaultReps: String?
    let defaultIntensity: String?
}

/// Teilweise Überschreibung einer Vorgabe (je Phase oder ohne Hangboard).
/// Alle Felder optional – nur gesetzte Werte ersetzen die Basisvorgabe.
struct OverrideSeed: Decodable {
    let exercise: String?
    let sets: Int?
    let reps: String?
    let rest: Int?
    let intensity: String?
    let weight: Double?
    let minutes: Int?
    let notes: String?
    let core: Bool?
    let limit: Bool?
}

/// Kurzform für den „Wenig Zeit“-Modus.
struct QuickSeed: Decodable {
    let sets: Int?
    let reps: String?
    let minutes: Int?
}

/// Eine Übung innerhalb einer Session-Vorlage inkl. Phasen-Logik.
struct SessionEntrySeed: Decodable {
    let exercise: String
    let core: Bool?
    /// Limit-Versuch – wird in der leichten Variante ausgeblendet.
    let limit: Bool?
    /// Benchmark-Art (maxHang, pullup3RM, moonGrade, kilterGrade).
    let benchmark: String?
    let sets: Int?
    let reps: String?
    let rest: Int?
    let intensity: String?
    let weight: Double?
    let minutes: Int?
    let notes: String?
    let onlyPhases: [String]?
    let exceptPhases: [String]?
    let onlyWeeks: [Int]?
    let exceptWeeks: [Int]?
    let phases: [String: OverrideSeed]?
    let noHangboard: OverrideSeed?
    let quick: QuickSeed?
}

/// Aufgelöste Vorgabe (Basis + Phasen-Override + ggf. Hangboard-Ersatz).
struct Prescription {
    var key: String
    var sets: Int
    var reps: String
    var rest: Int
    var intensity: String
    var weight: Double?
    var minutes: Int
    var notes: String
    var core: Bool
    var limit: Bool

    init(entry: SessionEntrySeed) {
        key = entry.exercise
        sets = entry.sets ?? 1
        reps = entry.reps ?? ""
        rest = entry.rest ?? 0
        intensity = entry.intensity ?? ""
        weight = entry.weight
        minutes = entry.minutes ?? 10
        notes = entry.notes ?? ""
        core = entry.core ?? false
        limit = entry.limit ?? false
    }

    /// Übernimmt alle im Override gesetzten Werte.
    mutating func apply(_ override: OverrideSeed) {
        if let v = override.exercise { key = v }
        if let v = override.sets { sets = v }
        if let v = override.reps { reps = v }
        if let v = override.rest { rest = v }
        if let v = override.intensity { intensity = v }
        if let v = override.weight { weight = v }
        if let v = override.minutes { minutes = v }
        if let v = override.notes { notes = v }
        if let v = override.core { core = v }
        if let v = override.limit { limit = v }
    }
}
