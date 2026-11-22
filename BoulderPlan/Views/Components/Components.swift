import SwiftUI

// MARK: - Session-Typ-Badge

/// Farbiges Quadrat mit dem Buchstaben des Session-Typs.
struct SessionTypeBadge: View {
    let type: SessionType
    var size: CGFloat = 44

    var body: some View {
        Text(type.rawValue)
            .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.28).fill(type.color.gradient))
            .accessibilityLabel("Session \(type.rawValue)")
    }
}

// MARK: - Fortschrittsring

/// Ring in Typfarbe: gestrichelt = offen, Teilring = teilweise, voll + Haken = erledigt, grau + X = übersprungen.
struct SessionRing: View {
    let session: TrainingSession
    var size: CGFloat = 34

    var body: some View {
        let color = session.type.color
        let status = session.status
        ZStack {
            Circle().fill(color.opacity(status == .skipped ? 0.08 : 0.22))
            switch status {
            case .open:
                Circle().strokeBorder(color.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            case .partial:
                Circle().strokeBorder(color.opacity(0.25), lineWidth: 3)
                Circle()
                    .inset(by: 1.5)
                    .trim(from: 0, to: session.progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            case .done:
                Circle().strokeBorder(color, lineWidth: 3)
            case .skipped:
                Circle().strokeBorder(Color.secondary.opacity(0.6), lineWidth: 1.5)
            }
            Group {
                switch status {
                case .done:
                    Image(systemName: "checkmark").font(.system(size: size * 0.42, weight: .heavy))
                case .skipped:
                    Image(systemName: "xmark").font(.system(size: size * 0.36, weight: .bold))
                default:
                    Text(session.type.rawValue).font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(status == .skipped ? Color.secondary : color)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.type.rawValue) \(session.title), \(status.label)")
    }
}

// MARK: - Große Checkbox

/// Große Tap-Fläche (52 pt) – bedienbar mit Kreide an den Fingern.
struct BigCheckbox: View {
    let isOn: Bool
    var color: Color = .accentColor
    var size: CGFloat = 52
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(isOn ? color : Color.clear)
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isOn ? color : Color.secondary.opacity(0.6), lineWidth: 3)
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .animation(.spring(duration: 0.25), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Erledigt" : "Offen")
    }
}

/// Runder Satz-Button (48 pt) mit Satznummer bzw. Haken.
struct SetButton: View {
    let index: Int
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(isOn ? color : Color.fieldBackground)
                if isOn {
                    Image(systemName: "checkmark").font(.headline.weight(.heavy)).foregroundStyle(.white)
                } else {
                    Text("\(index + 1)").font(.headline).foregroundStyle(.primary)
                }
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
            .animation(.spring(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Satz \(index + 1) \(isOn ? "erledigt" : "offen")")
    }
}

// MARK: - Aktionskachel

struct ActionTile: View {
    let title: String
    let systemImage: String
    let tint: Color
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.title2)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .foregroundStyle(isActive ? Color.black : tint)
            .background(RoundedRectangle(cornerRadius: 14).fill(isActive ? tint : tint.opacity(0.15)))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

/// Kleiner Aktionsbutton innerhalb einer aufgeklappten Übung.
struct SmallActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.fieldBackground))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Infozeile

struct InfoLine: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(color)
        }
    }
}

// MARK: - Session-Karte

/// Kompakte Darstellung einer Session (Listen, Wochenansicht, „Nächste Session“).
struct SessionCard: View {
    let session: TrainingSession
    var showDate = true
    var boxed = true

    var body: some View {
        HStack(spacing: 14) {
            SessionTypeBadge(type: session.type, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.title).font(.headline).lineLimit(1)
                if showDate {
                    Text(Fmt.dayLong(session.date)).font(.subheadline).foregroundStyle(.secondary)
                }
                Text("Woche \(session.week) · \(session.status.label)\(session.isOptional ? " · optional" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            SessionRing(session: session, size: 38)
        }
        .padding(boxed ? 14 : 0)
        .padding(.vertical, boxed ? 0 : 4)
        .background {
            if boxed { RoundedRectangle(cornerRadius: 16).fill(Color.fieldBackground) }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Karte mit Titel

struct Card<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: () -> Content

    init(title: String, systemImage: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
    }
}

// MARK: - Wochentagsauswahl

/// Sieben große Tasten Mo–So; es können höchstens `maxCount` Tage gewählt werden.
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    let maxCount: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { day in
                let isOn = selection.contains(day)
                Button {
                    toggle(day)
                } label: {
                    Text(Weekday.short(day))
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(isOn ? Color.white : Color.primary)
                        .background(RoundedRectangle(cornerRadius: 10).fill(isOn ? Color.accentColor : Color.fieldBackground))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ day: Int) {
        if selection.contains(day) {
            selection.remove(day)
            Haptics.selection()
        } else if selection.count < maxCount {
            selection.insert(day)
            Haptics.selection()
        } else {
            Haptics.warning()
        }
    }
}

// MARK: - Statistik-Kachel

struct StatTile: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(value).font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
    }
}
