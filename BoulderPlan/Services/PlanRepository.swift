import Foundation

/// Zusammenhängender Block gleicher Phase (z. B. Basis = Woche 1–3).
struct PhaseBlock: Identifiable {
    let phase: PhaseSeed
    var weeks: [Int]
    var id: Int { weeks.first ?? 0 }
}

/// Eintrag der Übungsbibliothek für Austausch-Dialoge.
struct LibraryItem: Identifiable {
    let key: String
    let exercise: ExerciseSeed
    var id: String { key }
}

struct LibraryGroup: Identifiable {
    let category: String
    let title: String
    let items: [LibraryItem]
    var id: String { category }
}

/// Lädt `plan_seed.json` einmalig aus dem App-Bundle und bietet bequeme Lookups.
final class PlanRepository {
    static let shared = PlanRepository()

    let seed: PlanSeed

    private init() {
        guard let url = Bundle.main.url(forResource: "plan_seed", withExtension: "json") else {
            fatalError("plan_seed.json fehlt im App-Bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            seed = try JSONDecoder().decode(PlanSeed.self, from: data)
        } catch {
            // Absichtlich laut: Ein Tippfehler in der JSON soll beim Bearbeiten sofort auffallen.
            fatalError("plan_seed.json konnte nicht gelesen werden: \(error)")
        }
    }

    var totalWeeks: Int { seed.weeks.count }

    func weekInfo(_ week: Int) -> WeekSeed? {
        seed.weeks.first { $0.week == week }
    }

    func phase(id: String) -> PhaseSeed? {
        seed.phases.first { $0.id == id }
    }

    func phase(forWeek week: Int) -> PhaseSeed? {
        weekInfo(week).flatMap { phase(id: $0.phase) }
    }

    func typeInfo(_ type: SessionType) -> SessionTypeSeed? {
        seed.sessionTypes[type.rawValue]
    }

    func title(for type: SessionType) -> String {
        typeInfo(type)?.title ?? type.defaultTitle
    }

    func layout(daysPerWeek: Int) -> WeekLayoutSeed? {
        seed.weekLayouts[String(daysPerWeek)]
    }

    func exercise(_ key: String) -> ExerciseSeed? {
        seed.exercises[key]
    }

    /// Wochen gruppiert nach aufeinanderfolgenden Phasen.
    var phaseBlocks: [PhaseBlock] {
        var blocks: [PhaseBlock] = []
        for week in seed.weeks.sorted(by: { $0.week < $1.week }) {
            if let last = blocks.last, last.phase.id == week.phase {
                blocks[blocks.count - 1].weeks.append(week.week)
            } else if let phase = phase(id: week.phase) {
                blocks.append(PhaseBlock(phase: phase, weeks: [week.week]))
            }
        }
        return blocks
    }

    /// Übungsbibliothek nach Kategorie gruppiert (ohne Benchmarks).
    var libraryGroups: [LibraryGroup] {
        let order = ["warmup", "fingers", "board", "technique", "strength", "antagonist", "core", "mobility"]
        let items = seed.exercises
            .filter { $0.value.category != "benchmark" }
            .map { LibraryItem(key: $0.key, exercise: $0.value) }
        let grouped = Dictionary(grouping: items) { $0.exercise.category }
        return grouped.keys
            .sorted { (order.firstIndex(of: $0) ?? 99) < (order.firstIndex(of: $1) ?? 99) }
            .map { category in
                LibraryGroup(
                    category: category,
                    title: Self.categoryTitle(category),
                    items: (grouped[category] ?? []).sorted { $0.exercise.name < $1.exercise.name }
                )
            }
    }

    static func categoryTitle(_ category: String) -> String {
        switch category {
        case "warmup": return "Aufwärmen"
        case "fingers": return "Fingerkraft"
        case "board": return "Board"
        case "technique": return "Technik"
        case "strength": return "Zugkraft"
        case "antagonist": return "Antagonisten & Schultern"
        case "core": return "Core"
        case "mobility": return "Mobility & Regeneration"
        case "benchmark": return "Benchmarks"
        default: return category.capitalized
        }
    }
}
