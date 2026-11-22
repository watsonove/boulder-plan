import Foundation
import SwiftData

/// Ergebnis eines Benchmarks in Woche 1 oder Woche 12.
@Model
final class BenchmarkResult {
    var id: UUID = UUID()
    var kindRaw: String = "maxHang"
    /// 1 (Ausgangstest) oder 12 (Abschlusstest).
    var week: Int = 1
    /// Zusatzgewicht in kg (Max Hang, 3RM).
    var value: Double? = nil
    /// Font-Grad (Moon-/Kilter-Benchmark).
    var grade: String? = nil
    var date: Date = Date()
    var note: String = ""

    init(kind: BenchmarkKind, week: Int) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.week = week
        self.date = .now
    }

    var kind: BenchmarkKind { BenchmarkKind(rawValue: kindRaw) ?? .maxHang }
}
