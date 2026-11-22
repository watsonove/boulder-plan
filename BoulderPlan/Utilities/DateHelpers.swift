import Foundation

extension Calendar {
    /// Gregorianischer Kalender mit Montag als Wochenbeginn (ISO-8601-Wochen).
    static let plan: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.locale = Locale(identifier: "de_DE")
        return calendar
    }()
}

extension Date {
    var startOfDay: Date { Calendar.plan.startOfDay(for: self) }

    func adding(days: Int) -> Date {
        Calendar.plan.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// ISO-Wochentag: 1 = Montag … 7 = Sonntag.
    var isoWeekday: Int {
        let weekday = Calendar.plan.component(.weekday, from: self) // 1 = Sonntag
        return weekday == 1 ? 7 : weekday - 1
    }

    /// Montag der Woche, in der dieses Datum liegt.
    var mondayOfWeek: Date { startOfDay.adding(days: -(isoWeekday - 1)) }

    /// Anzahl Kalendertage bis `other` (negativ, wenn `other` davor liegt).
    func days(to other: Date) -> Int {
        Calendar.plan.dateComponents([.day], from: startOfDay, to: other.startOfDay).day ?? 0
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.plan.isDate(self, inSameDayAs: other)
    }

    /// Heute, falls Montag – sonst der nächste Montag.
    static var nextMondayOrToday: Date {
        let today = Date().startOfDay
        return today.isoWeekday == 1 ? today : today.mondayOfWeek.adding(days: 7)
    }
}

enum Weekday {
    static let shortNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    static func short(_ iso: Int) -> String {
        shortNames[min(max(iso, 1), 7) - 1]
    }
}

/// Deutsche Datumsformate (unabhängig von der Systemsprache).
enum Fmt {
    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.calendar = Calendar.plan
        formatter.dateFormat = format
        return formatter
    }

    private static let dayLongFormatter = formatter("EEEE, d. MMMM")
    private static let weekdayShortDateFormatter = formatter("EE d.M.")
    private static let shortFormatter = formatter("d.M.")
    private static let dayMonthYearFormatter = formatter("d. MMM yyyy")
    private static let monthYearFormatter = formatter("LLLL yyyy")

    /// "Montag, 24. November"
    static func dayLong(_ date: Date) -> String { dayLongFormatter.string(from: date) }
    /// "Mo. 24.11."
    static func weekdayShortDate(_ date: Date) -> String { weekdayShortDateFormatter.string(from: date) }
    /// "24.11."
    static func short(_ date: Date) -> String { shortFormatter.string(from: date) }
    /// "24. Nov. 2026"
    static func dayMonthYear(_ date: Date) -> String { dayMonthYearFormatter.string(from: date) }
    /// "November 2026"
    static func monthYear(_ date: Date) -> String { monthYearFormatter.string(from: date) }
}

enum RestFormatter {
    /// 45 → "45 s", 120 → "2 min", 90 → "1:30 min"
    static func string(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) s" }
        let minutes = seconds / 60
        let rest = seconds % 60
        return rest == 0 ? "\(minutes) min" : String(format: "%d:%02d min", minutes, rest)
    }
}

extension Double {
    /// 12.5 → "12,5", 10.0 → "10"
    var cleanString: String {
        formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "de_DE")))
    }
}
