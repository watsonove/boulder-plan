import Foundation
import Observation
import SwiftData

/// Entwurf der Plan-Einstellungen – wird erst mit „Änderungen übernehmen“ angewendet,
/// weil das Neu-Erstellen zukünftiger Sessions eine bewusste Aktion sein soll.
@Observable
final class SettingsViewModel {
    var startDate = Date()
    var daysPerWeek = 4
    var weekdays: Set<Int> = [1, 2, 4, 6]
    var hasHangboard = false
    var showMobility = true
    var pauseDays = 7
    var message: String?

    func load(from s: AppSettings) {
        startDate = s.startDate
        daysPerWeek = s.daysPerWeek
        weekdays = Set(s.weekdays)
        hasHangboard = s.hasHangboard
        showMobility = s.showMobility
    }

    var weekdaysValid: Bool { weekdays.count == daysPerWeek }

    /// Anzahl Trainingstage ändern → Standard-Wochentage vorschlagen.
    func setDays(_ count: Int) {
        daysPerWeek = count
        weekdays = Set(PlanRepository.shared.layout(daysPerWeek: count)?.defaultWeekdays ?? [])
    }

    func startChanged(_ s: AppSettings) -> Bool {
        !s.startDate.mondayOfWeek.isSameDay(as: startDate.mondayOfWeek)
    }

    func hasChanges(comparedTo s: AppSettings) -> Bool {
        startChanged(s)
            || daysPerWeek != s.daysPerWeek
            || weekdays != Set(s.weekdays)
            || hasHangboard != s.hasHangboard
            || showMobility != s.showMobility
    }

    func apply(to s: AppSettings, context: ModelContext) {
        let fullRebuild = startChanged(s)
        s.startDate = startDate.mondayOfWeek
        s.daysPerWeek = daysPerWeek
        s.weekdays = weekdays.sorted()
        s.hasHangboard = hasHangboard
        s.showMobility = showMobility
        if fullRebuild {
            ScheduleService.regenerateAll(context: context, settings: s)
            message = "Der Plan wurde mit dem neuen Startdatum komplett neu erstellt."
        } else {
            ScheduleService.rebuildFuture(context: context, settings: s)
            message = "Zukünftige Sessions wurden an die neuen Einstellungen angepasst."
        }
        Haptics.success()
    }

    func pause(settings: AppSettings, context: ModelContext) {
        ScheduleService.pause(days: pauseDays, settings: settings, context: context)
        message = "Alle offenen Sessions ab heute wurden um \(pauseDays) Tage verschoben."
        Haptics.success()
    }

    func regenerate(settings: AppSettings, context: ModelContext) {
        ScheduleService.regenerateAll(context: context, settings: settings)
        message = "Der Plan wurde komplett neu erstellt."
        Haptics.success()
    }

    // MARK: - Erinnerungen

    func reminderDate(_ s: AppSettings) -> Date {
        Calendar.plan.date(bySettingHour: s.reminderHour, minute: s.reminderMinute, second: 0, of: .now) ?? .now
    }

    func setReminderTime(_ date: Date, settings: AppSettings, context: ModelContext) {
        let components = Calendar.plan.dateComponents([.hour, .minute], from: date)
        settings.reminderHour = components.hour ?? 17
        settings.reminderMinute = components.minute ?? 30
        try? context.save()
        NotificationService.reschedule(context: context)
    }

    func setReminders(_ enabled: Bool, settings: AppSettings, context: ModelContext) {
        settings.remindersEnabled = enabled
        try? context.save()
        guard enabled else {
            NotificationService.reschedule(context: context)
            return
        }
        Task { @MainActor in
            let granted = await NotificationService.requestAuthorization()
            if !granted {
                settings.remindersEnabled = false
                self.message = "Mitteilungen sind für Boulder Plan deaktiviert. Aktiviere sie in den iOS-Einstellungen."
            }
            try? context.save()
            NotificationService.reschedule(context: context)
        }
    }

    // MARK: - Export / Import

    func makeExport(context: ModelContext) -> BackupDocument? {
        do {
            return BackupDocument(data: try BackupService.exportData(context: context))
        } catch {
            message = "Export fehlgeschlagen: \(error.localizedDescription)"
            return nil
        }
    }

    func importBackup(from url: URL, settings: AppSettings, context: ModelContext) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            try BackupService.importData(data, context: context)
            load(from: settings)
            message = "Import erfolgreich."
            Haptics.success()
        } catch {
            message = "Import fehlgeschlagen: Die Datei ist kein gültiges Boulder-Plan-Backup.\n(\(error.localizedDescription))"
            Haptics.warning()
        }
    }

    var exportFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "BoulderPlan-Backup-\(formatter.string(from: .now))"
    }
}
