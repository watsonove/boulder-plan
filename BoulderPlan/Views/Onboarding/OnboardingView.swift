import SwiftUI
import SwiftData

/// Erster Start: Startdatum, Trainingstage, Hangboard und Erinnerungen festlegen – dann wird der Plan erzeugt.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var startDate = Date.nextMondayOrToday
    @State private var daysPerWeek = 4
    @State private var weekdays: Set<Int> = [1, 2, 4, 6]
    @State private var hasHangboard = false
    @State private var remindersEnabled = true
    @State private var reminderTime = Calendar.plan.date(bySettingHour: 17, minute: 30, second: 0, of: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                        Text("Willkommen bei Boulder Plan").font(.title2.bold())
                        Text("12 Wochen periodisiertes Bouldertraining – von 7a+ Richtung 7b/7b+: Basis, Maximalkraft, Power und Testwoche. Lege fest, wann du trainierst; der Kalender wird automatisch erstellt.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Start") {
                    DatePicker("Startdatum", selection: $startDate, displayedComponents: .date)
                    LabeledContent("Woche 1 beginnt", value: Fmt.dayLong(startDate.mondayOfWeek))
                }

                Section {
                    Picker("Trainingstage", selection: Binding(get: { daysPerWeek }, set: { newValue in
                        daysPerWeek = newValue
                        weekdays = Set(PlanRepository.shared.layout(daysPerWeek: newValue)?.defaultWeekdays ?? [])
                    })) {
                        Text("3 Tage").tag(3)
                        Text("4 Tage").tag(4)
                        Text("5 Tage").tag(5)
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        WeekdayPicker(selection: $weekdays, maxCount: daysPerWeek)
                        Text(PlanGenerator.layoutPreview(weekdays: weekdays, daysPerWeek: daysPerWeek))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(PlanGenerator.layoutWarnings(weekdays: weekdays, daysPerWeek: daysPerWeek), id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Trainingstage")
                } footer: {
                    Text("A = Limit & Finger · B = Kraft & Antagonisten · C = Kilter Power · D = Kraftausdauer · T = Technik (nur bei 5 Tagen). An freien Tagen gibt es optional Mobility (E).")
                }

                Section {
                    Toggle("Hangboard vorhanden", isOn: $hasHangboard)
                } header: {
                    Text("Equipment")
                } footer: {
                    Text("Vorausgesetzt: Kilterboard, Moonboard, Klimmzugstange, Gewichte, Hantelbank, Dip-Barren, Ringe. Ohne Hangboard werden Max Hangs automatisch durch Moonboard-Halteübungen ersetzt.")
                }

                Section("Erinnerungen") {
                    Toggle("An Trainingstagen erinnern", isOn: $remindersEnabled)
                    if remindersEnabled {
                        DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Button {
                        createPlan()
                    } label: {
                        Text("Plan erstellen")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(weekdays.count != daysPerWeek)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Boulder Plan")
        }
    }

    private func createPlan() {
        let settings = AppSettings()
        settings.startDate = startDate.mondayOfWeek
        settings.daysPerWeek = daysPerWeek
        settings.weekdays = weekdays.sorted()
        settings.hasHangboard = hasHangboard
        settings.remindersEnabled = remindersEnabled
        let components = Calendar.plan.dateComponents([.hour, .minute], from: reminderTime)
        settings.reminderHour = components.hour ?? 17
        settings.reminderMinute = components.minute ?? 30
        context.insert(settings)

        ScheduleService.regenerateAll(context: context, settings: settings)
        settings.planGenerated = true
        try? context.save()
        Haptics.success()

        if remindersEnabled {
            Task { @MainActor in
                let granted = await NotificationService.requestAuthorization()
                if !granted { settings.remindersEnabled = false }
                try? context.save()
                NotificationService.reschedule(context: context)
            }
        }
    }
}
