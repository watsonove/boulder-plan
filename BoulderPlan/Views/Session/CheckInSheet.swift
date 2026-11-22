import SwiftUI

/// Check-in vor der Session: Schlaf, Energie, Fingergefühl (je 1–5).
/// Bei niedrigen Werten wird die leichtere Variante empfohlen.
struct CheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let onApply: (_ sleep: Int, _ energy: Int, _ fingers: Int, _ useLight: Bool) -> Void

    @State private var sleep: Int
    @State private var energy: Int
    @State private var fingers: Int

    init(session: TrainingSession, onApply: @escaping (Int, Int, Int, Bool) -> Void) {
        self.session = session
        self.onApply = onApply
        _sleep = State(initialValue: session.checkInSleep ?? 3)
        _energy = State(initialValue: session.checkInEnergy ?? 3)
        _fingers = State(initialValue: session.checkInFingers ?? 3)
    }

    private var average: Double { Double(sleep + energy + fingers) / 3 }

    /// Empfehlung: leicht, wenn ein Wert ≤ 2 oder der Schnitt unter 2,7 liegt.
    private var recommendsLight: Bool { min(sleep, energy, fingers) <= 2 || average < 2.7 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Wie fühlst du dich heute? 1 = sehr schlecht, 5 = top.")
                        .foregroundStyle(.secondary)

                    RatingRow(title: "Schlaf", systemImage: "bed.double.fill", value: $sleep)
                    RatingRow(title: "Energie", systemImage: "bolt.heart.fill", value: $energy)
                    RatingRow(title: "Fingergefühl", systemImage: "hand.raised.fill", value: $fingers)

                    recommendation

                    VStack(spacing: 12) {
                        if recommendsLight {
                            primaryButton("Leichte Variante verwenden") { apply(light: true) }
                            secondaryButton("Trotzdem normal trainieren") { apply(light: false) }
                        } else {
                            primaryButton("Normal trainieren") { apply(light: false) }
                            secondaryButton("Leichte Variante wählen") { apply(light: true) }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    private var recommendation: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendsLight ? "tortoise.fill" : "flame.fill")
                .font(.title2)
                .foregroundStyle(recommendsLight ? Color.mint : Color.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendsLight ? "Empfehlung: leichtere Variante" : "Bereit für volles Training")
                    .font(.headline)
                Text(recommendsLight
                     ? "−1 Satz pro Übung und keine Limit-Versuche. Qualität vor Quantität – Finger schonen."
                     : "Gute Werte – trainiere nach Plan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func apply(light: Bool) {
        onApply(sleep, energy, fingers, light)
        dismiss()
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.bordered)
    }
}

/// Fünf große Tasten 1–5.
struct RatingRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage).font(.headline)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { number in
                    Button {
                        value = number
                        Haptics.selection()
                    } label: {
                        Text("\(number)")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .foregroundStyle(value == number ? Color.white : Color.primary)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(value == number ? color(for: number) : Color.fieldBackground))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func color(for number: Int) -> Color {
        switch number {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .mint
        }
    }
}
