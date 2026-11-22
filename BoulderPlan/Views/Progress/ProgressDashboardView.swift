import SwiftUI
import SwiftData
import Charts

struct BenchmarkSheetItem: Identifiable {
    let kind: BenchmarkKind
    let week: Int
    var id: String { "\(kind.rawValue)-\(week)" }
}

/// Tab „Fortschritt“: Serie, Abschlussquote pro Woche, Benchmarks Woche 1 vs. 12.
struct ProgressDashboardView: View {
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @Query private var results: [BenchmarkResult]
    @Query private var settingsList: [AppSettings]
    @State private var vm = ProgressViewModel()
    @State private var benchmarkItem: BenchmarkSheetItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statsGrid
                    weeklyChart
                    benchmarkCard
                }
                .padding()
            }
            .navigationTitle("Fortschritt")
            .sheet(item: $benchmarkItem) { item in
                BenchmarkEntrySheet(kind: item.kind, initialWeek: item.week)
            }
        }
    }

    // MARK: - Kennzahlen

    private var statsGrid: some View {
        let streak = vm.streaks(from: sessions)
        let totals = vm.totals(from: sessions)
        let rate = totals.due == 0 ? "–" : "\(Int((Double(totals.done) / Double(totals.due) * 100).rounded())) %"

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(title: "Serie", value: "\(streak.current)", subtitle: "Sessions in Folge",
                     systemImage: "flame.fill", tint: .orange)
            StatTile(title: "Rekord", value: "\(streak.longest)", subtitle: "längste Serie",
                     systemImage: "trophy.fill", tint: .yellow)
            StatTile(title: "Erledigt", value: "\(totals.done)", subtitle: "von \(totals.due) fälligen",
                     systemImage: "checkmark.seal.fill", tint: .green)
            StatTile(title: "Quote", value: rate, subtitle: "Abschluss bisher",
                     systemImage: "percent", tint: .blue)
        }
    }

    // MARK: - Wochenchart

    private var weeklyChart: some View {
        let current = ScheduleService.currentWeek(sessions: sessions, settings: settingsList.first)
        let stats = vm.weekStats(from: sessions, currentWeek: current)

        return Card(title: "Abschlussquote pro Woche", systemImage: "chart.bar.fill") {
            Chart(stats) { stat in
                BarMark(x: .value("Woche", stat.label),
                        y: .value("Abschluss", stat.rate * 100))
                    .foregroundStyle(stat.color.opacity(stat.isFuture ? 0.3 : 1))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        if stat.total > 0 && !stat.isFuture {
                            Text("\(Int((stat.rate * 100).rounded()))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
            .chartYScale(domain: 0.0...110.0)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.0, 50.0, 100.0])
            }
            .frame(height: 220)

            Text("Farbe = Phase. Optionale und übersprungene Sessions zählen nicht.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Benchmarks

    private var benchmarkCard: some View {
        let hasHangboard = settingsList.first?.hasHangboard ?? true
        return Card(title: "Benchmarks: Woche 1 vs. 12", systemImage: "trophy") {
            ForEach(BenchmarkKind.allCases) { kind in
                BenchmarkCompareRow(kind: kind,
                                    title: kind.title(hasHangboard: hasHangboard),
                                    start: vm.result(kind, week: 1, in: results),
                                    end: vm.result(kind, week: 12, in: results),
                                    vm: vm) { week in
                    benchmarkItem = BenchmarkSheetItem(kind: kind, week: week)
                }
                if kind != BenchmarkKind.allCases.last {
                    Divider()
                }
            }
            Text("Getestet wird in Woche 1 und 12 in den Sessions A (Max Hang, Moonboard, 3RM) und C (Kilter). Wert antippen zum Eintragen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct BenchmarkCompareRow: View {
    let kind: BenchmarkKind
    let title: String
    let start: BenchmarkResult?
    let end: BenchmarkResult?
    let vm: ProgressViewModel
    let onEdit: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: kind.systemImage).font(.subheadline.bold())
            HStack(spacing: 10) {
                valueButton(label: "Woche 1", text: vm.display(start, kind: kind)) { onEdit(1) }
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                valueButton(label: "Woche 12", text: vm.display(end, kind: kind)) { onEdit(12) }
                Spacer(minLength: 4)
                if let delta = vm.delta(kind: kind, start: start, end: end) {
                    Text(delta.text)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(delta.positive ? Color.green : Color.red)
                }
            }
        }
    }

    private func valueButton(label: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(text).font(.headline)
            }
            .frame(minWidth: 88, minHeight: 54)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.fieldBackground))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
