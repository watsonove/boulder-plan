import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Tab „Einstellungen“.
struct SettingsView: View {
    @Query private var settingsList: [AppSettings]

    var body: some View {
        NavigationStack {
            Group {
                if let settings = settingsList.first {
                    SettingsForm(settings: settings)
                } else {
                    ContentUnavailableView("Keine Einstellungen", systemImage: "gearshape")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

struct SettingsForm: View {
    @Environment(\.modelContext) private var context
    @Bindable var settings: AppSettings
    @State private var vm = SettingsViewModel()

    @State private var confirmApply = false
    @State private var confirmPause = false
    @State private var confirmRegenerate = false
    @State private var confirmImport = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument: BackupDocument?

    var body: some View {
        Form {
            planSection
            interruptionSection
            reminderSection
            appearanceSection
            dataSection
            infoSection
        }
        .onAppear { vm.load(from: settings) }
        .confirmationDialog("Änderungen übernehmen?", isPresented: $confirmApply, titleVisibility: .visible) {
            Button("Übernehmen") { vm.apply(to: settings, context: context) }
        } message: {
            Text(vm.startChanged(settings)
                 ? "Das Startdatum wurde geändert: Der gesamte Plan wird neu erstellt und der Fortschritt der Sessions geht verloren. Benchmarks bleiben erhalten."
                 : "Zukünftige, noch nicht begonnene Sessions werden neu erstellt. Verschobene, aber unberührte Termine werden zurückgesetzt.")
        }
        .confirmationDialog("Plan pausieren?", isPresented: $confirmPause, titleVisibility: .visible) {
            Button("Um \(vm.pauseDays) Tage verschieben") { vm.pause(settings: settings, context: context) }
        } message: {
            Text("Alle noch offenen Sessions ab heute rücken \(vm.pauseDays) Tage nach hinten.")
        }
        .confirmationDialog("Plan komplett neu erstellen?", isPresented: $confirmRegenerate, titleVisibility: .visible) {
            Button("Neu erstellen", role: .destructive) { vm.regenerate(settings: settings, context: context) }
        } message: {
            Text("Alle Sessions inkl. Haken und Notizen werden gelöscht und neu angelegt. Benchmarks bleiben erhalten.")
        }
        .confirmationDialog("Backup importieren?", isPresented: $confirmImport, titleVisibility: .visible) {
            Button("Datei auswählen", role: .destructive) { showImporter = true }
        } message: {
            Text("Alle aktuellen Sessions und Benchmarks werden durch den Inhalt der Datei ersetzt.")
        }
        .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .json,
                      defaultFilename: vm.exportFileName) { result in
            if case .failure(let error) = result {
                vm.message = "Export fehlgeschlagen: \(error.localizedDescription)"
            }
        }
        .alert("Boulder Plan", isPresented: Binding(get: { vm.message != nil }, set: { if !$0 { vm.message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.message ?? "")
        }
    }

    // MARK: - Plan

    private var planSection: some View {
        Section {
            DatePicker("Startdatum", selection: $vm.startDate, displayedComponents: .date)
            LabeledContent("Woche 1 beginnt", value: Fmt.dayLong(vm.startDate.mondayOfWeek))

            VStack(alignment: .leading, spacing: 10) {
                Text("Trainingstage pro Woche").font(.subheadline)
                Picker("Trainingstage pro Woche", selection: Binding(get: { vm.daysPerWeek }, set: { vm.setDays($0) })) {
                    Text("3 Tage").tag(3)
                    Text("4 Tage").tag(4)
                    Text("5 Tage").tag(5)
                }
                .pickerStyle(.segmented)

                Text("Wochentage (\(vm.weekdays.count)/\(vm.daysPerWeek))").font(.subheadline)
                WeekdayPicker(selection: $vm.weekdays, maxCount: vm.daysPerWeek)
                Text(PlanGenerator.layoutPreview(weekdays: vm.weekdays, daysPerWeek: vm.daysPerWeek))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(PlanGenerator.layoutWarnings(weekdays: vm.weekdays, daysPerWeek: vm.daysPerWeek), id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)

            Toggle("Hangboard vorhanden", isOn: $vm.hasHangboard)
            Toggle("Mobility (E) an freien Tagen", isOn: $vm.showMobility)

            Button {
                confirmApply = true
            } label: {
                Label("Änderungen übernehmen", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(!vm.hasChanges(comparedTo: settings) || !vm.weekdaysValid)
        } header: {
            Text("Plan")
        } footer: {
            Text("Ohne Hangboard werden Max Hangs automatisch durch Moonboard-Halteübungen ersetzt. 3 Tage: A, B (+Core), C/D im Wechsel · 4 Tage: A, B, C, D · 5 Tage: zusätzlich Technik/Volumen auf dem Kilter.")
        }
    }

    // MARK: - Krank / Urlaub

    private var interruptionSection: some View {
        Section {
            Stepper("Pausieren um \(vm.pauseDays) Tage", value: $vm.pauseDays, in: 1...60)
            Button {
                confirmPause = true
            } label: {
                Label("Plan pausieren & verschieben", systemImage: "pause.circle")
                    .frame(minHeight: 44)
            }
            if settings.shiftDays != 0 {
                LabeledContent("Bisher verschoben", value: "\(settings.shiftDays) Tage")
            }
        } header: {
            Text("Krank / Urlaub")
        } footer: {
            Text("Verschiebt alle noch offenen Sessions ab heute. Einzelne Wochen kannst du im Tab „Plan“ überspringen, verpasste Sessions im Tab „Heute“ nachholen.")
        }
    }

    // MARK: - Erinnerungen

    private var reminderSection: some View {
        Section {
            Toggle("Erinnerung an Trainingstagen",
                   isOn: Binding(get: { settings.remindersEnabled },
                                 set: { vm.setReminders($0, settings: settings, context: context) }))
            if settings.remindersEnabled {
                DatePicker("Uhrzeit",
                           selection: Binding(get: { vm.reminderDate(settings) },
                                              set: { vm.setReminderTime($0, settings: settings, context: context) }),
                           displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Erinnerungen")
        } footer: {
            Text("Lokale Mitteilung am Trainingstag zur gewählten Uhrzeit. Erledigte und übersprungene Sessions werden nicht erinnert.")
        }
    }

    // MARK: - Darstellung

    private var appearanceSection: some View {
        Section("Darstellung") {
            Toggle("Immer Dark Mode", isOn: $settings.forceDarkMode)
        }
    }

    // MARK: - Daten

    private var dataSection: some View {
        Section {
            Button {
                exportDocument = vm.makeExport(context: context)
                showExporter = exportDocument != nil
            } label: {
                Label("Fortschritt exportieren (JSON)", systemImage: "square.and.arrow.up")
                    .frame(minHeight: 44)
            }

            Button {
                confirmImport = true
            } label: {
                Label("Fortschritt importieren (JSON)", systemImage: "square.and.arrow.down")
                    .frame(minHeight: 44)
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    vm.importBackup(from: url, settings: settings, context: context)
                case .failure(let error):
                    vm.message = "Import abgebrochen: \(error.localizedDescription)"
                }
            }

            Button(role: .destructive) {
                confirmRegenerate = true
            } label: {
                Label("Plan komplett neu erstellen", systemImage: "arrow.counterclockwise")
                    .frame(minHeight: 44)
            }
        } header: {
            Text("Daten")
        } footer: {
            Text("Alle Daten liegen nur lokal auf deinem iPhone. Exportiere regelmäßig ein Backup (z. B. in die Dateien-App oder iCloud Drive).")
        }
    }

    private var infoSection: some View {
        Section("Info") {
            LabeledContent("Plan", value: PlanRepository.shared.seed.name)
            LabeledContent("Seed-Version", value: "\(PlanRepository.shared.seed.version)")
            LabeledContent("App-Version",
                           value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        }
    }
}
