import SwiftUI
import SwiftData

/// Sheets, die aus einer Session heraus geöffnet werden.
enum SessionSheet: Identifiable {
    case checkIn
    case move
    case addExercise
    case edit(SessionExercise)
    case swap(SessionExercise)
    case benchmark(BenchmarkKind, Int)

    var id: String {
        switch self {
        case .checkIn: return "checkIn"
        case .move: return "move"
        case .addExercise: return "add"
        case .edit(let exercise): return "edit-\(exercise.id)"
        case .swap(let exercise): return "swap-\(exercise.id)"
        case .benchmark(let kind, let week): return "bench-\(kind.rawValue)-\(week)"
        }
    }
}

/// Vollständige Session: Kopfkarte, Aktionen, abhakbare Übungsliste, Notizen.
/// Wird im Tab „Heute“ (mit eigenem Header) und aus Kalender/Plan heraus verwendet.
struct SessionDetailView<Header: View>: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: TrainingSession
    private let header: () -> Header

    @Query(sort: \TrainingSession.date) private var allSessions: [TrainingSession]
    @Query private var settingsList: [AppSettings]

    @State private var vm = SessionViewModel()
    @State private var activeSheet: SessionSheet?
    @State private var confirmReset = false
    @State private var confirmSkip = false
    @State private var infoMessage: String?

    init(session: TrainingSession, @ViewBuilder header: @escaping () -> Header) {
        self._session = Bindable(wrappedValue: session)
        self.header = header
    }

    private var settings: AppSettings? { settingsList.first }

    private var conflicts: [TrainingSession] {
        ScheduleService.fingerConflicts(for: session, on: session.date, among: allSessions)
    }

    var body: some View {
        List {
            if Header.self != EmptyView.self {
                Section { header() }
            }

            Section {
                SessionHeaderCard(session: session, conflicts: conflicts)
            }

            Section {
                actionGrid
            }

            exerciseSection

            Section("Notizen zur Session") {
                TextField("Wie lief's? Beta, Gefühl, Gewichte …", text: $session.notes, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { moreMenu }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetView(for: sheet)
        }
        .confirmationDialog("Fortschritt zurücksetzen?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) { vm.resetProgress(session, context: context) }
        } message: {
            Text("Alle Haken, der Check-in und die Modi dieser Session werden entfernt.")
        }
        .confirmationDialog("Session überspringen?", isPresented: $confirmSkip, titleVisibility: .visible) {
            Button("Überspringen", role: .destructive) { vm.setSkipped(true, session, context: context) }
        } message: {
            Text("Die Session wird als übersprungen markiert und zählt nicht in die Abschlussquote.")
        }
        .alert("Hinweis", isPresented: Binding(get: { infoMessage != nil }, set: { if !$0 { infoMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(infoMessage ?? "")
        }
    }

    // MARK: - Aktionen

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ActionTile(title: session.hasCheckIn ? "Check-in ✓" : "Check-in",
                       systemImage: "heart.text.square", tint: .pink, isActive: session.hasCheckIn) {
                activeSheet = .checkIn
            }
            ActionTile(title: "Wenig Zeit", systemImage: "timer", tint: .yellow, isActive: session.quickMode) {
                vm.toggleQuickMode(session, context: context)
            }
            ActionTile(title: "Leichte Variante", systemImage: "tortoise.fill", tint: .mint, isActive: session.lightMode) {
                vm.toggleLightMode(session, context: context)
            }
            ActionTile(title: "Verschieben", systemImage: "calendar.badge.clock", tint: .blue) {
                activeSheet = .move
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Übungen

    private var exerciseSection: some View {
        Section {
            ForEach(session.visibleExercises) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    accent: session.type.color,
                    onToggle: { vm.toggle(exercise, in: session, context: context) },
                    onToggleSet: { index in vm.toggleSet(index, of: exercise, in: session, context: context) },
                    onEdit: { activeSheet = .edit(exercise) },
                    onSwap: { activeSheet = .swap(exercise) },
                    onBenchmark: benchmarkAction(for: exercise)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        vm.delete(exercise, from: session, context: context)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                    Button {
                        activeSheet = .swap(exercise)
                    } label: {
                        Label("Tauschen", systemImage: "arrow.left.arrow.right")
                    }
                    .tint(.indigo)
                }
            }

            Button {
                activeSheet = .addExercise
            } label: {
                Label("Eigene Übung hinzufügen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            }
        } header: {
            Text("Übungen")
        } footer: {
            exerciseFooter
        }
    }

    private var exerciseFooter: some View {
        let hidden = session.sortedExercises.count - session.visibleExercises.count
        return VStack(alignment: .leading, spacing: 4) {
            Text("★ = Kernübung. Die Session gilt als erledigt, sobald alle Kernübungen abgehakt sind. Übung antippen zum Aufklappen (Sätze, Notiz, Tauschen).")
            if hidden > 0 {
                Text("\(hidden) Übung(en) ausgeblendet (Wenig-Zeit-Modus bzw. keine Limit-Versuche in der leichten Variante).")
            }
        }
    }

    private func benchmarkAction(for exercise: SessionExercise) -> (() -> Void)? {
        guard let kind = exercise.benchmark else { return nil }
        let week = session.week >= 12 ? 12 : 1
        return { activeSheet = .benchmark(kind, week) }
    }

    // MARK: - Menü

    private var moreMenu: some View {
        Menu {
            Button { activeSheet = .checkIn } label: { Label("Check-in", systemImage: "heart.text.square") }
            Button { activeSheet = .move } label: { Label("Verschieben", systemImage: "calendar.badge.clock") }
            Button { makeUp() } label: { Label("Nachholen (nächste freie Lücke)", systemImage: "arrow.uturn.forward") }
            Button { activeSheet = .addExercise } label: { Label("Übung hinzufügen", systemImage: "plus") }
            Divider()
            if session.isSkipped {
                Button { vm.setSkipped(false, session, context: context) } label: {
                    Label("Wiederherstellen", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button(role: .destructive) { confirmSkip = true } label: {
                    Label("Überspringen", systemImage: "forward.end")
                }
            }
            Button(role: .destructive) { confirmReset = true } label: {
                Label("Fortschritt zurücksetzen", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .frame(minWidth: 44, minHeight: 44)
        }
    }

    private func makeUp() {
        if let day = vm.makeUp(session, all: allSessions, context: context) {
            infoMessage = "Session auf \(Fmt.dayLong(day)) gelegt."
        } else {
            infoMessage = "In den nächsten drei Wochen wurde keine freie Lücke ohne 48-h-Konflikt gefunden."
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetView(for sheet: SessionSheet) -> some View {
        switch sheet {
        case .checkIn:
            CheckInSheet(session: session) { sleep, energy, fingers, light in
                vm.applyCheckIn(session, sleep: sleep, energy: energy, fingers: fingers, useLight: light, context: context)
            }
        case .move:
            MoveSessionSheet(session: session,
                             days: settings.map { PlanGenerator.weekDates(session.week, settings: $0) } ?? [],
                             allSessions: allSessions) { day in
                vm.move(session, to: day, context: context)
            }
        case .addExercise:
            EditExerciseSheet(title: "Eigene Übung", draft: ExerciseDraft()) { draft in
                vm.addCustom(draft, to: session, context: context)
            }
        case .edit(let exercise):
            EditExerciseSheet(title: "Übung bearbeiten", draft: ExerciseDraft(exercise)) { draft in
                vm.save(draft, to: exercise, context: context)
            }
        case .swap(let exercise):
            SwapExerciseSheet(exercise: exercise) { key in
                vm.swap(exercise, toKey: key, context: context)
            }
        case .benchmark(let kind, let week):
            BenchmarkEntrySheet(kind: kind, initialWeek: week)
        }
    }
}

extension SessionDetailView where Header == EmptyView {
    init(session: TrainingSession) {
        self.init(session: session) { EmptyView() }
    }
}

// MARK: - Kopfkarte

struct SessionHeaderCard: View {
    let session: TrainingSession
    let conflicts: [TrainingSession]

    private var phaseName: String {
        PlanRepository.shared.phase(id: session.phaseId)?.name ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SessionTypeBadge(type: session.type, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title).font(.title3.bold())
                    Text("Woche \(session.week) · \(phaseName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.phase(session.phaseId))
                    Text(Fmt.dayLong(session.date)).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                SessionRing(session: session, size: 46)
            }

            ProgressView(value: session.progress)
                .tint(session.type.color)
                .scaleEffect(x: 1, y: 2.2, anchor: .center)
                .padding(.vertical, 4)

            HStack {
                Label(session.status.label, systemImage: session.status.systemImage)
                    .foregroundStyle(session.status.color)
                Spacer()
                Text("\(session.completedRequiredCount)/\(session.requiredExercises.count) Kern · ≈ \(session.estimatedMinutes) min")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            if session.isOptional {
                InfoLine(systemImage: "leaf.fill", text: "Optionale Session – zählt nicht in Statistik und Serie.", color: .mint)
            }
            if session.quickMode {
                InfoLine(systemImage: "timer", text: "Wenig Zeit: nur Kernübungen in Kurzform (≈ 45 min).", color: .yellow)
            }
            if session.lightMode {
                InfoLine(systemImage: "tortoise.fill", text: "Leichte Variante: −1 Satz pro Übung, keine Limit-Versuche.", color: .mint)
            }
            if let summary = session.checkInSummary {
                InfoLine(systemImage: "heart.text.square", text: summary, color: .pink)
            }
            if !conflicts.isEmpty {
                InfoLine(systemImage: "exclamationmark.triangle.fill",
                         text: "Weniger als 48 h Abstand zu: "
                            + conflicts.map { "\($0.type.rawValue) (\(Fmt.weekdayShortDate($0.date)))" }.joined(separator: ", "),
                         color: .orange)
            }
            if session.isMissed {
                InfoLine(systemImage: "clock.badge.exclamationmark",
                         text: "Verpasst – über ⋯ „Nachholen“ oder „Überspringen“.", color: .orange)
            }
        }
        .padding(.vertical, 6)
    }
}
