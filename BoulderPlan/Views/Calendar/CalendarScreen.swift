import SwiftUI
import SwiftData

/// Tab „Kalender“: Monats- und Wochenansicht. In der Wochenansicht Sessions per Drag & Drop verschieben.
struct CalendarScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TrainingSession.date) private var sessions: [TrainingSession]
    @Query private var settingsList: [AppSettings]
    @State private var vm = CalendarViewModel()

    var body: some View {
        NavigationStack {
            let byDay = vm.sessionsByDay(sessions)
            VStack(spacing: 10) {
                Picker("Ansicht", selection: $vm.mode) {
                    ForEach(CalendarMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                navigationHeader

                if vm.mode == .month {
                    ScrollView {
                        MonthGridView(days: vm.monthDays,
                                      isInMonth: vm.isInDisplayedMonth,
                                      sessionsByDay: byDay) { day in
                            vm.selectedDay = day
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 40).onEnded { value in
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                withAnimation { vm.step(value.translation.width < 0 ? 1 : -1) }
                            }
                        )
                        CalendarLegend().padding()
                    }
                } else {
                    WeekPlannerView(days: vm.weekDays,
                                    sessionsByDay: byDay,
                                    targetedDay: $vm.targetedDay,
                                    onDrop: { id, day in
                                        vm.handleDrop(id, onto: day, sessions: sessions,
                                                      settings: settingsList.first, context: context)
                                    },
                                    onOpenDay: { vm.selectedDay = $0 })
                }
            }
            .navigationTitle("Kalender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Heute") { withAnimation { vm.goToToday() } }
                }
            }
            .navigationDestination(item: $vm.selectedDay) { day in
                DayView(date: day)
            }
            .alert("Weniger als 48 h Erholung",
                   isPresented: Binding(get: { vm.pendingDrop != nil }, set: { if !$0 { vm.pendingDrop = nil } })) {
                Button("Trotzdem verschieben", role: .destructive) { vm.confirmPendingDrop(context: context) }
                Button("Abbrechen", role: .cancel) { vm.pendingDrop = nil }
            } message: {
                Text(vm.pendingDropMessage)
            }
            .alert("Hinweis",
                   isPresented: Binding(get: { vm.infoMessage != nil }, set: { if !$0 { vm.infoMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.infoMessage ?? "")
            }
        }
    }

    private var navigationHeader: some View {
        HStack {
            Button {
                withAnimation { vm.step(-1) }
            } label: {
                Image(systemName: "chevron.left").font(.title3.weight(.semibold)).frame(width: 44, height: 44)
            }
            Spacer()
            Text(vm.title).font(.headline)
            Spacer()
            Button {
                withAnimation { vm.step(1) }
            } label: {
                Image(systemName: "chevron.right").font(.title3.weight(.semibold)).frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Monatsraster

struct MonthGridView: View {
    let days: [Date]
    let isInMonth: (Date) -> Bool
    let sessionsByDay: [Date: [TrainingSession]]
    let onSelect: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(Weekday.shortNames, id: \.self) { name in
                    Text(name)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days, id: \.self) { day in
                    Button {
                        onSelect(day)
                    } label: {
                        DayCell(day: day,
                                sessions: sessionsByDay[day.startOfDay] ?? [],
                                inMonth: isInMonth(day),
                                isToday: day.isSameDay(as: .now))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Ein Tag im Monatsraster: Tageszahl + Fortschrittsring der Session (Farbe = Typ).
struct DayCell: View {
    let day: Date
    let sessions: [TrainingSession]
    let inMonth: Bool
    let isToday: Bool

    var body: some View {
        let main = sessions.filter { !$0.isOptional }
        let hasOptional = sessions.contains { $0.isOptional }

        VStack(spacing: 3) {
            Text("\(Calendar.plan.component(.day, from: day))")
                .font(.subheadline.weight(isToday ? .heavy : .medium))
                .foregroundStyle(inMonth ? Color.primary : Color.secondary)
            ZStack(alignment: .topTrailing) {
                if let first = main.first {
                    SessionRing(session: first, size: 32)
                } else if hasOptional {
                    Circle()
                        .fill(SessionType.E.color.opacity(0.7))
                        .frame(width: 9, height: 9)
                        .frame(width: 32, height: 32)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }
                if main.count > 1 {
                    Text("+\(main.count - 1)")
                        .font(.system(size: 9, weight: .bold))
                        .padding(2)
                        .background(Circle().fill(Color(.systemBackground)))
                        .offset(x: 6, y: -4)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isToday ? Color.accentColor.opacity(0.2) : Color.cardBackground)
        )
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 10).strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
        .opacity(inMonth ? 1 : 0.45)
        .contentShape(Rectangle())
    }
}

// MARK: - Legende

struct CalendarLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legende").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(SessionType.allCases) { type in
                    HStack(spacing: 8) {
                        SessionTypeBadge(type: type, size: 24)
                        Text(PlanRepository.shared.title(for: type)).font(.caption)
                    }
                }
            }
            Divider()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], alignment: .leading, spacing: 8) {
                legendItem("Offen", "gestrichelter Ring")
                legendItem("Teilweise", "Teilring")
                legendItem("Erledigt", "voller Ring + ✓")
                legendItem("Übersprungen", "grau + ✕")
                HStack(spacing: 8) {
                    Circle().fill(SessionType.E.color.opacity(0.7)).frame(width: 9, height: 9)
                    Text("Optionale Mobility").font(.caption)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func legendItem(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.caption.bold())
            Text(detail).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
