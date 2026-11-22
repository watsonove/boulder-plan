import SwiftUI

extension Color {
    /// Farbnamen aus der Seed-JSON (z. B. Phasenfarben) in SwiftUI-Farben übersetzen.
    static func named(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default: return .gray
        }
    }

    /// Farbe einer Phase anhand ihrer ID.
    static func phase(_ phaseId: String) -> Color {
        named(PlanRepository.shared.phase(id: phaseId)?.color ?? "gray")
    }

    static let cardBackground = Color(.secondarySystemBackground)
    static let fieldBackground = Color(.tertiarySystemFill)
}
