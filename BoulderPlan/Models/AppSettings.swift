import Foundation
import SwiftData

/// App-Einstellungen (genau ein Datensatz).
@Model
final class AppSettings {
    /// Startdatum – der Plan beginnt am Montag dieser Woche.
    var startDate: Date = Date()
    /// 3, 4 oder 5 Trainingstage pro Woche.
    var daysPerWeek: Int = 4
    /// Gewählte Wochentage (ISO: 1 = Montag … 7 = Sonntag).
    var weekdays: [Int] = [1, 2, 4, 6]
    /// Ohne Hangboard werden Hangboard-Übungen durch Board-Alternativen ersetzt.
    var hasHangboard: Bool = false
    /// Optionale Mobility-Session (E) an freien Tagen anlegen.
    var showMobility: Bool = true
    var remindersEnabled: Bool = false
    var reminderHour: Int = 17
    var reminderMinute: Int = 30
    /// Summe aller Pausen-Verschiebungen in Tagen (Krankheit/Urlaub).
    var shiftDays: Int = 0
    var forceDarkMode: Bool = true
    /// Wurde der Plan nach dem Onboarding erzeugt?
    var planGenerated: Bool = false

    init() {
        self.startDate = Date.nextMondayOrToday
    }
}
