import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case today, calendar, plan, progress, settings
}

/// Wurzel: Onboarding bis ein Plan existiert, danach die Tab-Leiste.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsList: [AppSettings]
    @State private var selectedTab: AppTab = .today

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        Group {
            if let settings, settings.planGenerated {
                TabView(selection: $selectedTab) {
                    TodayView()
                        .tabItem { Label("Heute", systemImage: "checklist") }
                        .tag(AppTab.today)
                    CalendarScreen()
                        .tabItem { Label("Kalender", systemImage: "calendar") }
                        .tag(AppTab.calendar)
                    PlanOverviewView()
                        .tabItem { Label("Plan", systemImage: "list.bullet.rectangle") }
                        .tag(AppTab.plan)
                    ProgressDashboardView()
                        .tabItem { Label("Fortschritt", systemImage: "chart.bar.fill") }
                        .tag(AppTab.progress)
                    SettingsView()
                        .tabItem { Label("Einstellungen", systemImage: "gearshape") }
                        .tag(AppTab.settings)
                }
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme((settings?.forceDarkMode ?? true) ? .dark : nil)
        .environment(\.locale, Locale(identifier: "de_DE"))
        .onChange(of: scenePhase) { _, newPhase in
            // Beim Zurückkehren in die App Erinnerungen aktualisieren (z. B. neuer Tag).
            if newPhase == .active { NotificationService.reschedule(context: context) }
        }
    }
}
