import Foundation
import SwiftData
import UserNotifications

/// Lokale Erinnerungen an Trainingstagen (UserNotifications, kein Server nötig).
enum NotificationService {

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func reschedule(context: ModelContext) {
        guard let settings = ScheduleService.fetchSettings(context) else { return }
        reschedule(sessions: ScheduleService.fetchSessions(context), settings: settings)
    }

    /// Entfernt alle geplanten Erinnerungen und plant die nächsten Trainingstage neu.
    /// iOS erlaubt max. 64 ausstehende Mitteilungen – wir planen die nächsten 60.
    static func reschedule(sessions: [TrainingSession], settings: AppSettings) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard settings.remindersEnabled else { return }

        let now = Date()
        let upcoming = sessions.compactMap { session -> (session: TrainingSession, fireDate: Date)? in
            guard !session.isOptional, !session.isSkipped, !session.isDone else { return nil }
            guard let fire = Calendar.plan.date(bySettingHour: settings.reminderHour,
                                                minute: settings.reminderMinute,
                                                second: 0, of: session.date),
                  fire > now else { return nil }
            return (session, fire)
        }
        .sorted { $0.fireDate < $1.fireDate }

        for item in upcoming.prefix(60) {
            let session = item.session
            let content = UNMutableNotificationContent()
            content.title = "Trainingstag: \(session.type.rawValue) – \(session.title)"
            let phase = PlanRepository.shared.phase(id: session.phaseId)?.name ?? ""
            content.body = "Woche \(session.week) · \(phase). Kurzer Check-in vor dem Start? 💪"
            content.sound = .default

            let components = Calendar.plan.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "session-\(session.id.uuidString)",
                                                content: content, trigger: trigger)
            center.add(request) { _ in }
        }
    }
}
