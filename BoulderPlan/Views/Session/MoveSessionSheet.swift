import SwiftUI

/// Verschiebt eine Session auf einen anderen Tag derselben Trainingswoche.
/// Warnt, wenn fingerintensive Sessions (A, C) weniger als 48 h auseinanderliegen würden.
struct MoveSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let days: [Date]
    let allSessions: [TrainingSession]
    let onMove: (Date) -> Void

    @State private var pendingDay: Date?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(days, id: \.self) { day in
                        Button { select(day) } label: { dayRow(day) }
                            .buttonStyle(.plain)
                    }
                } header: {
                    Text("Trainingswoche \(session.week)")
                } footer: {
                    Text("Sessions können innerhalb ihrer Trainingswoche verschoben werden. Fingerintensive Sessions (A, C) sollten mindestens 48 h auseinanderliegen. Für spätere Termine nutze „Nachholen“.")
                }
            }
            .navigationTitle("\(session.type.rawValue) verschieben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .alert("Weniger als 48 h Erholung",
                   isPresented: Binding(get: { pendingDay != nil }, set: { if !$0 { pendingDay = nil } })) {
                Button("Trotzdem verschieben", role: .destructive) {
                    if let day = pendingDay { commit(day) }
                }
                Button("Abbrechen", role: .cancel) { pendingDay = nil }
            } message: {
                Text(conflictMessage)
            }
        }
    }

    private func conflicts(on day: Date) -> [TrainingSession] {
        ScheduleService.fingerConflicts(for: session, on: day, among: allSessions)
    }

    private func select(_ day: Date) {
        if day.isSameDay(as: session.date) {
            dismiss()
        } else if conflicts(on: day).isEmpty {
            commit(day)
        } else {
            Haptics.warning()
            pendingDay = day
        }
    }

    private func commit(_ day: Date) {
        onMove(day)
        dismiss()
    }

    private var conflictMessage: String {
        guard let day = pendingDay else { return "" }
        let list = conflicts(on: day)
            .map { "\($0.type.rawValue) – \($0.title) am \(Fmt.weekdayShortDate($0.date))" }
            .joined(separator: "\n")
        return "Fingerintensive Sessions sollten mindestens 48 h auseinanderliegen:\n\n\(list)"
    }

    @ViewBuilder
    private func dayRow(_ day: Date) -> some View {
        let others = allSessions.filter { $0.id != session.id && !$0.isOptional && $0.date.isSameDay(as: day) }
        let isCurrent = day.isSameDay(as: session.date)
        let hasConflict = !isCurrent && !conflicts(on: day).isEmpty

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Fmt.dayLong(day)).font(.headline)
                if others.isEmpty {
                    Text("frei").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Bereits: " + others.map { "\($0.type.rawValue) \($0.title)" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isCurrent {
                Text("aktuell")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(session.type.color.opacity(0.3)))
            } else if hasConflict {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.title3)
            } else {
                Image(systemName: "arrow.right.circle").foregroundStyle(.secondary).font(.title3)
            }
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
