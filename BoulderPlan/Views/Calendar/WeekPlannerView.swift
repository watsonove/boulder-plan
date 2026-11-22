import SwiftUI

/// Wochenansicht: ein Block pro Tag. Sessions lassen sich per Long-Press auf andere Tage ziehen.
struct WeekPlannerView: View {
    let days: [Date]
    let sessionsByDay: [Date: [TrainingSession]]
    @Binding var targetedDay: Date?
    let onDrop: (String, Date) -> Bool
    let onOpenDay: (Date) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Label("Session gedrückt halten und auf einen anderen Tag ziehen, um sie zu verschieben.",
                      systemImage: "hand.draw")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(days, id: \.self) { day in
                    dayBlock(day)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func dayBlock(_ day: Date) -> some View {
        let items = sessionsByDay[day.startOfDay] ?? []
        let isToday = day.isSameDay(as: .now)
        let isTargeted = targetedDay.map { $0.isSameDay(as: day) } ?? false

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                onOpenDay(day)
            } label: {
                HStack {
                    Text(Fmt.dayLong(day)).font(.headline)
                    if isToday {
                        Text("Heute")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .frame(minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if items.isEmpty {
                Text("Ruhetag")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            } else {
                ForEach(items) { session in
                    NavigationLink {
                        SessionDetailView(session: session).navigationTitle(session.title)
                    } label: {
                        SessionCard(session: session, showDate: false)
                    }
                    .buttonStyle(.plain)
                    .draggable(session.id.uuidString) {
                        SessionCard(session: session, showDate: false)
                            .frame(width: 280)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isTargeted ? Color.accentColor.opacity(0.25) : Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isTargeted ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.5) : Color.clear),
                              lineWidth: 2)
        )
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            targetedDay = nil
            return onDrop(id, day)
        } isTargeted: { targeted in
            if targeted {
                targetedDay = day
            } else if targetedDay?.isSameDay(as: day) == true {
                targetedDay = nil
            }
        }
    }
}
