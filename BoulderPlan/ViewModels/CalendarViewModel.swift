import Foundation
import Observation
import SwiftData

enum CalendarMode: String, CaseIterable, Identifiable {
    case month, week
    var id: String { rawValue }
    var title: String { self == .month ? "Monat" : "Woche" }
}

/// Verschieben per Drag & Drop, das wegen der 48-h-Regel bestätigt werden muss.
struct PendingDrop {
    let session: TrainingSession
    let date: Date
    let conflicts: [TrainingSession]
}

@Observable
final class CalendarViewModel {
    var mode: CalendarMode = .month
    /// Ein beliebiges Datum im angezeigten Monat bzw. in der angezeigten Woche.
    var anchor: Date = .now
    /// Für die Navigation zur Tagesansicht.
    var selectedDay: Date?
    /// Tag, über dem gerade eine Session gezogen wird.
    var targetedDay: Date?
    var pendingDrop: PendingDrop?
    var infoMessage: String?

    // MARK: - Navigation

    var title: String {
        switch mode {
        case .month:
            return Fmt.monthYear(anchor)
        case .week:
            let days = weekDays
            let week = Calendar.plan.component(.weekOfYear, from: anchor)
            return "KW \(week) · \(Fmt.short(days.first ?? anchor)) – \(Fmt.short(days.last ?? anchor))"
        }
    }

    func step(_ direction: Int) {
        let component: Calendar.Component = mode == .month ? .month : .weekOfYear
        anchor = Calendar.plan.date(byAdding: component, value: direction, to: anchor) ?? anchor
    }

    func goToToday() { anchor = .now }

    // MARK: - Tage

    /// Alle Tage, die im Monatsraster angezeigt werden (volle Wochen Mo–So).
    var monthDays: [Date] {
        guard let interval = Calendar.plan.dateInterval(of: .month, for: anchor) else { return [] }
        let first = interval.start.mondayOfWeek
        let lastDayOfMonth = interval.end.adding(days: -1)
        let last = lastDayOfMonth.mondayOfWeek.adding(days: 6)
        let count = first.days(to: last) + 1
        return (0..<count).map { first.adding(days: $0) }
    }

    var weekDays: [Date] {
        let monday = anchor.mondayOfWeek
        return (0..<7).map { monday.adding(days: $0) }
    }

    func isInDisplayedMonth(_ day: Date) -> Bool {
        Calendar.plan.isDate(day, equalTo: anchor, toGranularity: .month)
    }

    func sessionsByDay(_ sessions: [TrainingSession]) -> [Date: [TrainingSession]] {
        Dictionary(grouping: sessions) { $0.date.startOfDay }
            .mapValues { $0.sorted { !$0.isOptional && $1.isOptional } }
    }

    // MARK: - Drag & Drop

    /// Verarbeitet einen Drop. Gibt `true` zurück, wenn der Drop angenommen wurde.
    func handleDrop(_ idString: String, onto day: Date, sessions: [TrainingSession],
                    settings: AppSettings?, context: ModelContext) -> Bool {
        guard let uuid = UUID(uuidString: idString),
              let session = sessions.first(where: { $0.id == uuid }) else { return false }
        if session.date.isSameDay(as: day) { return false }

        switch ScheduleService.checkMove(session, to: day, among: sessions, settings: settings) {
        case .ok:
            ScheduleService.move(session, to: day, context: context)
            Haptics.success()
            return true
        case .outsideWeek:
            infoMessage = "Sessions lassen sich nur innerhalb ihrer Trainingswoche (Woche \(session.week)) verschieben. Für spätere Termine nutze „Nachholen“."
            Haptics.warning()
            return false
        case .fingerConflict(let conflicts):
            pendingDrop = PendingDrop(session: session, date: day, conflicts: conflicts)
            Haptics.warning()
            return true
        }
    }

    func confirmPendingDrop(context: ModelContext) {
        guard let drop = pendingDrop else { return }
        ScheduleService.move(drop.session, to: drop.date, context: context)
        pendingDrop = nil
        Haptics.success()
    }

    var pendingDropMessage: String {
        guard let drop = pendingDrop else { return "" }
        let list = drop.conflicts
            .map { "\($0.type.rawValue) – \($0.title) (\(Fmt.weekdayShortDate($0.date)))" }
            .joined(separator: "\n")
        return "Fingerintensive Sessions (A, C) sollten mindestens 48 h auseinanderliegen:\n\n\(list)"
    }
}
