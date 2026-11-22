import SwiftUI
import SwiftData

/// Tab „Plan“: 12-Wochen-Übersicht nach Phasen, aktuelle Woche hervorgehoben.
struct PlanOverviewView: View {
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @Query private var settingsList: [AppSettings]
    @State private var vm = PlanViewModel()
    private let repo = PlanRepository.shared

    var body: some View {
        NavigationStack {
            let current = ScheduleService.currentWeek(sessions: sessions, settings: settingsList.first)
            ScrollViewReader { proxy in
                List {
                    Section {
                        PlanSummaryCard(currentWeek: current, sessions: sessions)
                    }
                    ForEach(repo.phaseBlocks) { block in
                        let color = Color.named(block.phase.color)
                        Section {
                            ForEach(block.weeks, id: \.self) { week in
                                let weekSessions = vm.sessions(inWeek: week, from: sessions)
                                NavigationLink {
                                    WeekDetailView(week: week)
                                } label: {
                                    WeekRow(week: week,
                                            isCurrent: week == current,
                                            sessions: weekSessions,
                                            completion: vm.completion(of: weekSessions),
                                            dateRange: vm.dateRange(week: week, sessions: sessions, settings: settingsList.first),
                                            color: color)
                                }
                                .id(week)
                                .listRowBackground(week == current ? color.opacity(0.18) : nil)
                            }
                        } header: {
                            PhaseHeader(block: block)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .onAppear {
                    guard (1...repo.totalWeeks).contains(current) else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation { proxy.scrollTo(current, anchor: .center) }
                    }
                }
            }
            .navigationTitle("12-Wochen-Plan")
        }
    }
}

struct PlanSummaryCard: View {
    let currentWeek: Int
    let sessions: [TrainingSession]

    var body: some View {
        let repo = PlanRepository.shared
        let total = repo.totalWeeks
        let main = sessions.filter { !$0.isOptional }

        VStack(alignment: .leading, spacing: 8) {
            Text(repo.seed.name).font(.headline)
            if currentWeek > total {
                Text("Plan abgeschlossen – Zeit für den Vergleich der Benchmarks! 🎉")
                    .font(.subheadline)
            } else {
                Text("Aktuell: Woche \(max(currentWeek, 1)) von \(total) · \(repo.phase(forWeek: max(currentWeek, 1))?.name ?? "")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.phase(repo.weekInfo(max(currentWeek, 1))?.phase ?? ""))
            }
            ProgressView(value: Double(min(max(currentWeek - 1, 0), total)), total: Double(total))
                .tint(.accentColor)
            if let first = main.first?.date, let last = main.last?.date {
                Text("\(Fmt.dayMonthYear(first)) – \(Fmt.dayMonthYear(last))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PhaseHeader: View {
    let block: PhaseBlock

    private var weeksText: String {
        guard let first = block.weeks.first, let last = block.weeks.last else { return "" }
        return first == last ? "Woche \(first)" : "Woche \(first)–\(last)"
    }

    var body: some View {
        let color = Color.named(block.phase.color)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(block.phase.name).font(.headline).foregroundStyle(color)
                Spacer()
                Text(weeksText).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Text(block.phase.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }
}

struct WeekRow: View {
    let week: Int
    let isCurrent: Bool
    let sessions: [TrainingSession]
    let completion: Double
    let dateRange: String
    let color: Color

    var body: some View {
        let main = sessions.filter { !$0.isOptional }
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Woche \(week)").font(.headline)
                    if isCurrent {
                        Text("AKTUELL")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(color))
                            .foregroundStyle(.white)
                    }
                }
                Text(dateRange).font(.caption).foregroundStyle(.secondary)
                if let focus = PlanRepository.shared.weekInfo(week)?.focus {
                    Text(focus).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack(spacing: 6) {
                    ForEach(main) { SessionRing(session: $0, size: 28) }
                }
            }
            Spacer()
            Text("\(Int((completion * 100).rounded())) %")
                .font(.headline.monospacedDigit())
                .foregroundStyle(completion >= 1 ? Color.green : Color.secondary)
        }
        .padding(.vertical, 6)
    }
}

/// Alle Sessions einer Woche + „Woche überspringen“.
struct WeekDetailView: View {
    let week: Int
    @Environment(\.modelContext) private var context
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @State private var confirmSkip = false

    private var weekSessions: [TrainingSession] { sessions.filter { $0.week == week } }

    var body: some View {
        let repo = PlanRepository.shared
        List {
            if let info = repo.weekInfo(week), let phase = repo.phase(id: info.phase) {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(phase.name).font(.headline).foregroundStyle(Color.named(phase.color))
                        Text(info.focus)
                        Text(phase.description).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Sessions") {
                ForEach(weekSessions.filter { !$0.isOptional }) { session in
                    NavigationLink {
                        SessionDetailView(session: session).navigationTitle(session.title)
                    } label: {
                        SessionCard(session: session, boxed: false)
                    }
                }
            }

            let optional = weekSessions.filter(\.isOptional)
            if !optional.isEmpty {
                Section("Optional: Mobility") {
                    ForEach(optional) { session in
                        NavigationLink {
                            SessionDetailView(session: session).navigationTitle(session.title)
                        } label: {
                            SessionCard(session: session, boxed: false)
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmSkip = true
                } label: {
                    Label("Woche überspringen", systemImage: "forward.end.alt")
                        .frame(minHeight: 44)
                }
            } footer: {
                Text("Markiert alle noch offenen Sessions dieser Woche als übersprungen (z. B. bei Krankheit oder Urlaub). Zum Verschieben des gesamten Plans nutze „Plan pausieren“ in den Einstellungen.")
            }
        }
        .navigationTitle("Woche \(week)")
        .confirmationDialog("Woche \(week) überspringen?", isPresented: $confirmSkip, titleVisibility: .visible) {
            Button("Überspringen", role: .destructive) {
                ScheduleService.skipWeek(week, context: context)
                Haptics.warning()
            }
        }
    }
}
