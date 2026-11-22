import SwiftUI

/// Übung austauschen: empfohlene Alternativen (z. B. Kilter ↔ Moonboard) oder beliebige Übung aus der Bibliothek.
struct SwapExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: SessionExercise
    let onSelect: (String) -> Void

    @State private var search = ""
    private let repo = PlanRepository.shared

    var body: some View {
        NavigationStack {
            List {
                let alternatives = exercise.alternatives.filter { repo.exercise($0) != nil }
                if !alternatives.isEmpty && search.isEmpty {
                    Section("Empfohlene Alternativen") {
                        ForEach(alternatives, id: \.self) { key in row(key) }
                    }
                }
                ForEach(repo.libraryGroups) { group in
                    let items = group.items.filter { matches($0) && $0.key != exercise.key }
                    if !items.isEmpty {
                        Section(group.title) {
                            ForEach(items) { item in row(item.key) }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Übung suchen")
            .navigationTitle("\(exercise.name) tauschen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    private func matches(_ item: LibraryItem) -> Bool {
        search.isEmpty || item.exercise.name.localizedCaseInsensitiveContains(search)
    }

    @ViewBuilder
    private func row(_ key: String) -> some View {
        if let library = repo.exercise(key) {
            Button {
                onSelect(key)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(library.name).font(.headline)
                    Text(library.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
