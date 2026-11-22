import SwiftUI
import SwiftData

/// Benchmark-Ergebnis für Woche 1 oder 12 eintragen.
struct BenchmarkEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var results: [BenchmarkResult]
    @Query private var settingsList: [AppSettings]

    let kind: BenchmarkKind
    @State private var week: Int
    @State private var value: Double = 0
    @State private var grade: String = "7a+"
    @State private var note: String = ""

    init(kind: BenchmarkKind, initialWeek: Int) {
        self.kind = kind
        _week = State(initialValue: initialWeek)
    }

    private var hasHangboard: Bool { settingsList.first?.hasHangboard ?? true }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(kind.instructions(hasHangboard: hasHangboard)).font(.callout)
                }

                Section("Zeitpunkt") {
                    Picker("Woche", selection: $week) {
                        Text("Woche 1").tag(1)
                        Text("Woche 12").tag(12)
                    }
                    .pickerStyle(.segmented)
                }

                if kind.isGrade {
                    Section("Grad (Fb)") {
                        Picker("Grad", selection: $grade) {
                            ForEach(FontGrade.all, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                } else {
                    Section {
                        HStack {
                            TextField("kg", value: $value, format: .number)
                                .keyboardType(.numbersAndPunctuation)
                                .font(.title2.bold())
                            Text("kg").foregroundStyle(.secondary)
                            Stepper("", value: $value, in: -60...200, step: 1.25)
                                .labelsHidden()
                        }
                    } header: {
                        Text("Zusatzgewicht")
                    } footer: {
                        Text("Negativ = Entlastung (z. B. Flaschenzug).")
                    }
                }

                Section("Notiz") {
                    TextField("z. B. Griffposition, Problemname", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(kind.title(hasHangboard: hasHangboard))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                }
            }
            .onAppear(perform: load)
            .onChange(of: week) { _, _ in load() }
        }
    }

    private func load() {
        if let existing = results.first(where: { $0.kindRaw == kind.rawValue && $0.week == week }) {
            value = existing.value ?? 0
            grade = existing.grade ?? grade
            note = existing.note
        } else {
            note = ""
        }
    }

    private func save() {
        BenchmarkService.upsert(kind: kind, week: week,
                                value: kind.isGrade ? nil : value,
                                grade: kind.isGrade ? grade : nil,
                                note: note, context: context)
        Haptics.success()
        dismiss()
    }
}
