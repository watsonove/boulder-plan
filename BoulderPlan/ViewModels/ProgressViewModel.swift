import SwiftUI

@Observable
final class ProgressViewModel {

    struct WeekStat: Identifiable {
        let week: Int
        let done: Int
        let total: Int
        let color: Color
        let isFuture: Bool
        var id: Int { week }
        var label: String { "W\(week)" }
        var rate: Double { total == 0 ? 0 : Double(done) / Double(total) }
    }

    /// Abschlussquote je Woche (ohne optionale und übersprungene Sessions).
    func weekStats(from sessions: [TrainingSession], currentWeek: Int) -> [WeekStat] {
        PlanRepository.shared.seed.weeks.map { info in
            let relevant = sessions.filter { $0.week == info.week && !$0.isOptional && !$0.isSkipped }
            return WeekStat(week: info.week,
                            done: relevant.filter(\.isDone).count,
                            total: relevant.count,
                            color: .phase(info.phase),
                            isFuture: info.week > currentWeek)
        }
    }

    /// Serie = erledigte Pflicht-Sessions in Folge. Übersprungene Sessions (krank/Urlaub)
    /// sind neutral, verpasste Sessions in der Vergangenheit brechen die Serie.
    func streaks(from sessions: [TrainingSession], today: Date = .now) -> (current: Int, longest: Int) {
        let relevant = sessions.filter { !$0.isOptional && !$0.isSkipped }.sorted { $0.date < $1.date }
        let todayStart = today.startOfDay

        var longest = 0
        var running = 0
        for session in relevant {
            if session.isDone {
                running += 1
                longest = max(longest, running)
            } else if session.date.startOfDay < todayStart {
                running = 0
            }
        }

        var current = 0
        for session in relevant.reversed() {
            if session.isDone { current += 1; continue }
            if session.date.startOfDay >= todayStart { continue } // heute/zukünftig: noch offen, zählt nicht
            break
        }
        return (current, longest)
    }

    /// Erledigte vs. bis heute fällige Pflicht-Sessions.
    func totals(from sessions: [TrainingSession], today: Date = .now) -> (done: Int, due: Int) {
        let main = sessions.filter { !$0.isOptional && !$0.isSkipped }
        let due = main.filter { $0.date.startOfDay <= today.startOfDay || $0.isDone }.count
        return (main.filter(\.isDone).count, due)
    }

    // MARK: - Benchmarks

    func result(_ kind: BenchmarkKind, week: Int, in results: [BenchmarkResult]) -> BenchmarkResult? {
        results.first { $0.kindRaw == kind.rawValue && $0.week == week }
    }

    func display(_ result: BenchmarkResult?, kind: BenchmarkKind) -> String {
        guard let result else { return "–" }
        if kind.isGrade { return result.grade ?? "–" }
        guard let value = result.value else { return "–" }
        return (value > 0 ? "+" : "") + value.cleanString + " kg"
    }

    /// Veränderung von Woche 1 zu Woche 12.
    func delta(kind: BenchmarkKind, start: BenchmarkResult?, end: BenchmarkResult?) -> (text: String, positive: Bool)? {
        guard let start, let end else { return nil }
        if kind.isGrade {
            guard let g1 = start.grade, let g2 = end.grade,
                  let i1 = FontGrade.index(of: g1), let i2 = FontGrade.index(of: g2) else { return nil }
            let diff = i2 - i1
            let unit = abs(diff) == 1 ? "Grad" : "Grade"
            let text = diff == 0 ? "±0" : (diff > 0 ? "+\(diff) \(unit)" : "\(diff) \(unit)")
            return (text, diff >= 0)
        }
        guard let v1 = start.value, let v2 = end.value else { return nil }
        let diff = v2 - v1
        return ((diff > 0 ? "+" : "") + diff.cleanString + " kg", diff >= 0)
    }
}
