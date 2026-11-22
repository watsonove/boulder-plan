import UIKit

/// Haptisches Feedback – deutlich spürbar, damit man auch mit Kreide an den Fingern merkt, dass der Tap ankam.
enum Haptics {
    /// Übung/Satz abgehakt.
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Kleine Auswahländerung.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Session komplett erledigt oder Aktion erfolgreich.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warnung, z. B. weniger als 48 h zwischen Fingersessions.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
