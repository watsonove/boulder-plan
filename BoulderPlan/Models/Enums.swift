import SwiftUI

// MARK: - Session-Typen

/// Die Session-Typen des Plans. Inhalte kommen aus der Seed-JSON,
/// Farbe/Symbol/Fingerbelastung sind hier fest definiert.
enum SessionType: String, Codable, CaseIterable, Identifiable {
    case A, B, C, D, E, T

    var id: String { rawValue }

    /// Klare, gut unterscheidbare Farbe je Typ (auch im Dark Mode).
    var color: Color {
        switch self {
        case .A: return Color(red: 0.94, green: 0.27, blue: 0.27) // Rot
        case .B: return Color(red: 0.23, green: 0.51, blue: 0.96) // Blau
        case .C: return Color(red: 0.98, green: 0.55, blue: 0.13) // Orange
        case .D: return Color(red: 0.66, green: 0.33, blue: 0.97) // Violett
        case .E: return Color(red: 0.18, green: 0.80, blue: 0.67) // Mint
        case .T: return Color(red: 0.92, green: 0.75, blue: 0.10) // Gelb
        }
    }

    /// Fallback-Titel, falls in der JSON keiner hinterlegt ist.
    var defaultTitle: String {
        switch self {
        case .A: return "Limit & Finger"
        case .B: return "Kraft & Antagonisten"
        case .C: return "Kilter Power"
        case .D: return "Kraftausdauer & Volumen"
        case .E: return "Mobility & Regeneration"
        case .T: return "Technik & Volumen"
        }
    }

    var systemImage: String {
        switch self {
        case .A: return "hand.raised.fingers.spread.fill"
        case .B: return "dumbbell.fill"
        case .C: return "bolt.fill"
        case .D: return "arrow.triangle.2.circlepath"
        case .E: return "figure.cooldown"
        case .T: return "figure.climbing"
        }
    }

    /// Fingerintensive Sessions sollen mindestens 48 h auseinanderliegen.
    var isFingerIntensive: Bool { self == .A || self == .C }
}

// MARK: - Status

enum SessionStatus: String {
    case open, partial, done, skipped

    var label: String {
        switch self {
        case .open: return "Offen"
        case .partial: return "Teilweise"
        case .done: return "Erledigt"
        case .skipped: return "Übersprungen"
        }
    }

    var systemImage: String {
        switch self {
        case .open: return "circle.dashed"
        case .partial: return "circle.lefthalf.filled"
        case .done: return "checkmark.circle.fill"
        case .skipped: return "forward.end.circle"
        }
    }

    var color: Color {
        switch self {
        case .open: return .gray
        case .partial: return .orange
        case .done: return .green
        case .skipped: return .gray
        }
    }
}

// MARK: - Benchmarks

/// Benchmarks, die in Woche 1 und 12 getestet und verglichen werden.
enum BenchmarkKind: String, Codable, CaseIterable, Identifiable {
    case maxHang, pullup3RM, moonGrade, kilterGrade

    var id: String { rawValue }

    func title(hasHangboard: Bool = true) -> String {
        switch self {
        case .maxHang: return hasHangboard ? "Max Hang 20 mm (10 s)" : "Board-Halteübung (7 s)"
        case .pullup3RM: return "3RM gewichtete Klimmzüge"
        case .moonGrade: return "Höchster Moonboard-Grad"
        case .kilterGrade: return "Höchster Kilter-Grad"
        }
    }

    func instructions(hasHangboard: Bool) -> String {
        switch self {
        case .maxHang:
            return hasHangboard
                ? "Maximales Zusatzgewicht, das du 10 s an der 20-mm-Leiste im Halbkrimp halten kannst."
                : "Maximales Zusatzgewicht für 7 s an deiner festen Moonboard-Position (immer dieselben Griffe)."
        case .pullup3RM:
            return "Zusatzgewicht, mit dem du genau 3 saubere Klimmzüge schaffst."
        case .moonGrade:
            return "Höchster gekletterter Grad am Moonboard 40° innerhalb der Testsession."
        case .kilterGrade:
            return "Höchster gekletterter Grad am Kilterboard 40° innerhalb der Testsession."
        }
    }

    var isGrade: Bool { self == .moonGrade || self == .kilterGrade }

    var systemImage: String {
        switch self {
        case .maxHang: return "hand.raised.fill"
        case .pullup3RM: return "figure.strengthtraining.traditional"
        case .moonGrade: return "moon.stars.fill"
        case .kilterGrade: return "square.grid.3x3.fill"
        }
    }
}

/// Fontainebleau-Boulderskala für Picker und Vergleiche.
enum FontGrade {
    static let all = ["5c", "6a", "6a+", "6b", "6b+", "6c", "6c+", "7a", "7a+",
                      "7b", "7b+", "7c", "7c+", "8a", "8a+", "8b"]

    static func index(of grade: String) -> Int? {
        all.firstIndex(of: grade.lowercased())
    }
}
