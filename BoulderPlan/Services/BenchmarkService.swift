import Foundation
import SwiftData

enum BenchmarkService {
    /// Legt ein Benchmark-Ergebnis an oder aktualisiert das vorhandene (je Art + Woche genau eins).
    static func upsert(kind: BenchmarkKind, week: Int, value: Double?, grade: String?, note: String, context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<BenchmarkResult>())) ?? []
        let result: BenchmarkResult
        if let existing = all.first(where: { $0.kindRaw == kind.rawValue && $0.week == week }) {
            result = existing
        } else {
            result = BenchmarkResult(kind: kind, week: week)
            context.insert(result)
        }
        result.value = value
        result.grade = grade
        result.note = note
        result.date = .now
        try? context.save()
    }
}
