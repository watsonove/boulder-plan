import SwiftUI

/// Übung bearbeiten oder eigene Übung anlegen: Sätze, Wiederholungen, Pause, Intensität, Gewicht.
struct EditExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSave: (ExerciseDraft) -> Void
    @State private var draft: ExerciseDraft

    init(title: String, draft: ExerciseDraft, onSave: @escaping (ExerciseDraft) -> Void) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Übung") {
                    TextField("Name", text: $draft.name)
                        .font(.headline)
                    TextField("Beschreibung / Ausführung", text: $draft.info, axis: .vertical)
                        .lineLimit(2...6)
                    Toggle("Kernübung", isOn: $draft.isCore)
                }

                Section("Vorgabe") {
                    Stepper("Sätze: \(draft.sets)", value: $draft.sets, in: 1...15)
                    LabeledContent("Wdh. / Dauer") {
                        TextField("z. B. 8–10 oder 10 s", text: $draft.reps)
                            .multilineTextAlignment(.trailing)
                    }
                    Stepper("Pause: \(RestFormatter.string(draft.restSeconds))", value: $draft.restSeconds, in: 0...600, step: 15)
                    LabeledContent("Intensität") {
                        TextField("Grad, RPE …", text: $draft.intensity)
                            .multilineTextAlignment(.trailing)
                    }
                    Stepper("Dauer: \(draft.minutes) min", value: $draft.minutes, in: 1...120, step: 1)
                }

                Section {
                    Toggle("Zusatzgewicht erfassen", isOn: $draft.hasWeight)
                    if draft.hasWeight {
                        HStack {
                            TextField("kg", value: $draft.weightKg, format: .number)
                                .keyboardType(.numbersAndPunctuation)
                                .font(.title3.bold())
                            Text("kg").foregroundStyle(.secondary)
                            Stepper("", value: $draft.weightKg, in: -60...200, step: 1.25)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text("Gewicht")
                } footer: {
                    Text("Negativer Wert = Entlastung (z. B. Flaschenzug oder Band).")
                }

                Section("Notiz") {
                    TextField("Notiz", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...5)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        onSave(draft)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }
}
