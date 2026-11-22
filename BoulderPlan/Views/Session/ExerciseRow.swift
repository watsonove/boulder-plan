import SwiftUI

/// Eine Übung als große Checkbox-Zeile. Aufklappbar für Satz-Häkchen, Beschreibung, Notiz und Aktionen.
struct ExerciseRow: View {
    @Bindable var exercise: SessionExercise
    let accent: Color
    let onToggle: () -> Void
    let onToggleSet: (Int) -> Void
    let onEdit: () -> Void
    let onSwap: () -> Void
    let onBenchmark: (() -> Void)?

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                BigCheckbox(isOn: exercise.isCompleted, color: accent, action: onToggle)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .strikethrough(exercise.isCompleted)
                                    .foregroundStyle(exercise.isCompleted ? Color.secondary : Color.primary)
                                if exercise.isCore {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                        .accessibilityLabel("Kernübung")
                                }
                                if exercise.benchmark != nil {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .accessibilityLabel("Benchmark")
                                }
                            }
                            Text(exercise.prescriptionText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if exercise.effectiveSets > 1 {
                                Text("\(exercise.doneSetCount)/\(exercise.effectiveSets) Sätze")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(accent)
                            }
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.down")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                            .frame(width: 36, height: 44)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if expanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 6)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !exercise.info.isEmpty {
                Text(exercise.info)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if exercise.effectiveSets > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sätze abhaken").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0..<exercise.effectiveSets, id: \.self) { index in
                                SetButton(index: index, isOn: exercise.isCompleted || exercise.isSetDone(index), color: accent) {
                                    onToggleSet(index)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            TextField("Notiz (Gewicht, Gefühl, Beta …)", text: $exercise.notes, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.fieldBackground))

            HStack(spacing: 8) {
                SmallActionButton(title: "Bearbeiten", systemImage: "slider.horizontal.3", action: onEdit)
                SmallActionButton(title: "Tauschen", systemImage: "arrow.left.arrow.right", action: onSwap)
                if let onBenchmark {
                    SmallActionButton(title: "Ergebnis", systemImage: "trophy", action: onBenchmark)
                }
            }
        }
    }
}
