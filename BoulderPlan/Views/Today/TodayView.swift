import SwiftUI
import SwiftData

/// Tab „Heute“: die heutige Session als Checkbox-Liste – oder Ruhetag mit Vorschau.
struct TodayView: View {
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @State private var vm = TodayViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Heute")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var content: some View {
        let today = Date()
        let todays = vm.sessions(on: today, from: sessions)
        let missed = vm.missedSessions(from: sessions)

        if let session = vm.selectedSession(from: todays) {
            SessionDetailView(session: session) {
                TodayHeader(date: today, week: session.week, isRestDay: session.isOptional)
                if todays.count > 1 {
                    Picker("Session", selection: Binding(get: { session.id }, set: { vm.selectedID = $0 })) {
                        ForEach(todays) { item in
                            Text(item.isOptional ? "\(item.type.rawValue) · optional" : "\(item.type.rawValue) · \(item.title)")
                                .tag(item.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if !missed.isEmpty {
                    MissedBanner(count: missed.count)
                }
            }
            .id(session.id)
        } else {
            RestDayView(today: today,
                        next: vm.nextSession(after: today, from: sessions),
                        missedCount: missed.count,
                        state: vm.planState(from: sessions, today: today))
        }
    }
}

/// Kopfbereich mit Datum, Woche, Phase und Wochenfokus.
struct TodayHeader: View {
    let date: Date
    let week: Int
    var isRestDay = false

    var body: some View {
        let repo = PlanRepository.shared
        VStack(alignment: .leading, spacing: 4) {
            Text(Fmt.dayLong(date)).font(.title2.bold())
            if let info = repo.weekInfo(week) {
                Text("Woche \(week) · \(repo.phase(id: info.phase)?.name ?? "")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.phase(info.phase))
                Text(isRestDay ? "Ruhetag – optionale Mobility für die Regeneration." : info.focus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Hinweis auf verpasste Sessions mit Link zur Nachholen/Überspringen-Liste.
struct MissedBanner: View {
    let count: Int

    var body: some View {
        NavigationLink {
            MissedSessionsView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 1 ? "1 verpasste Session" : "\(count) verpasste Sessions").font(.headline)
                    Text("Nachholen oder überspringen").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
    }
}

/// Ruhetag, Plan noch nicht gestartet oder bereits abgeschlossen.
struct RestDayView: View {
    let today: Date
    let next: TrainingSession?
    let missedCount: Int
    let state: PlanState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)
                Text(title).font(.title.bold())
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if missedCount > 0 {
                    MissedBanner(count: missedCount)
                        .buttonStyle(.plain)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
                }

                if let next {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nächste Session").font(.headline)
                        NavigationLink {
                            SessionDetailView(session: next).navigationTitle(next.title)
                        } label: {
                            SessionCard(session: next)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    private var icon: String {
        switch state {
        case .notStarted: return "calendar.badge.clock"
        case .finished: return "trophy.fill"
        case .running: return "moon.zzz.fill"
        }
    }

    private var title: String {
        switch state {
        case .notStarted: return "Bald geht's los"
        case .finished: return "Plan abgeschlossen!"
        case .running: return "Ruhetag"
        }
    }

    private var subtitle: String {
        switch state {
        case .notStarted(let date):
            return "Dein 12-Wochen-Plan startet am \(Fmt.dayLong(date))."
        case .finished:
            return "Stark! Trage deine Benchmarks aus Woche 12 im Tab „Fortschritt“ ein und vergleiche sie mit Woche 1."
        case .running:
            return "Erholung ist Teil des Trainings. Finger, Schultern und Kopf regenerieren lassen."
        }
    }
}

/// Liste verpasster Sessions mit „Nachholen“ und „Überspringen“.
struct MissedSessionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @State private var message: String?

    private var missed: [TrainingSession] { sessions.filter(\.isMissed) }

    var body: some View {
        List {
            if missed.isEmpty {
                ContentUnavailableView("Alles im Plan", systemImage: "checkmark.seal",
                                       description: Text("Keine verpassten Sessions."))
            }
            ForEach(missed) { session in
                VStack(alignment: .leading, spacing: 12) {
                    SessionCard(session: session, boxed: false)
                    HStack(spacing: 10) {
                        Button {
                            makeUp(session)
                        } label: {
                            Label("Nachholen", systemImage: "arrow.uturn.forward")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(session.type.color)

                        Button {
                            session.isSkipped = true
                            Haptics.warning()
                            ScheduleService.didChangeSchedule(context)
                        } label: {
                            Label("Überspringen", systemImage: "forward.end")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 6)
            }
            if missed.count > 1 {
                Section {
                    Button("Alle überspringen", role: .destructive) {
                        missed.forEach { $0.isSkipped = true }
                        Haptics.warning()
                        ScheduleService.didChangeSchedule(context)
                    }
                }
            }
        }
        .navigationTitle("Verpasste Sessions")
        .alert("Nachholen", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func makeUp(_ session: TrainingSession) {
        if let day = ScheduleService.makeUp(session, among: sessions, context: context) {
            Haptics.success()
            message = "\(session.type.rawValue) – \(session.title) liegt jetzt auf \(Fmt.dayLong(day))."
        } else {
            Haptics.warning()
            message = "Keine freie Lücke ohne 48-h-Konflikt in den nächsten drei Wochen gefunden."
        }
    }
}
