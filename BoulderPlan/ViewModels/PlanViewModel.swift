import Foundation
import Observation

@Observable
final class PlanViewModel {
    func sessions(inWeek week: Int, from all: [TrainingSession]) -> [TrainingSession] {
        all.filter { $0.week == week }.sorted { $0.date < $1.date }
    }

    /// Abschlussquote einer Woche (übersprungene und optionale Sessions zählen nicht).
    func completion(of sessions: [TrainingSession]) -> Double {
        let relevant = sessions.filter { !$0.isOptional && !$0.isSkipped }
        guard !relevant.isEmpty else { return 0 }
        return Double(relevant.filter(\.isDone).count) / Double(relevant.count)
    }

    /// Zeitraum einer Woche – aus den Sessions, sonst aus den Einstellungen berechnet.
    func dateRange(week: Int, sessions: [TrainingSession], settings: AppSettings?) -> String {
        let weekSessions = sessions.filter { $0.week == week }
        if let first = weekSessions.map(\.date).min(), let last = weekSessions.map(\.date).max() {
            return "\(Fmt.weekdayShortDate(first)) – \(Fmt.weekdayShortDate(last))"
        }
        guard let settings else { return "" }
        let days = PlanGenerator.weekDates(week, settings: settings)
        guard let first = days.first, let last = days.last else { return "" }
        return "\(Fmt.weekdayShortDate(first)) – \(Fmt.weekdayShortDate(last))"
    }
}
