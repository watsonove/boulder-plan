import SwiftUI
import SwiftData

/// Tagesansicht aus dem Kalender. Bei genau einer Session direkt deren Detailansicht.
struct DayView: View {
    let date: Date
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]

    private var daySessions: [TrainingSession] {
        sessions.filter { $0.date.isSameDay(as: date) }
            .sorted { !$0.isOptional && $1.isOptional }
    }

    var body: some View {
        Group {
            if daySessions.count == 1, let only = daySessions.first {
                SessionDetailView(session: only)
            } else if daySessions.isEmpty {
                ContentUnavailableView("Ruhetag", systemImage: "moon.zzz",
                                       description: Text("An diesem Tag ist keine Session geplant."))
            } else {
                List {
                    ForEach(daySessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session).navigationTitle(session.title)
                        } label: {
                            SessionCard(session: session, showDate: false, boxed: false)
                        }
                    }
                }
            }
        }
        .navigationTitle(Fmt.dayLong(date))
        .navigationBarTitleDisplayMode(.inline)
    }
}
