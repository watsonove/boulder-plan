import SwiftUI
import SwiftData

/// Einstiegspunkt der App. Alle Daten liegen lokal in SwiftData – kein Backend, kein Login.
@main
struct BoulderPlanApp: App {
    let container: ModelContainer = {
        let schema = Schema([
            TrainingSession.self,
            SessionExercise.self,
            AppSettings.self,
            BenchmarkResult.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData-Container konnte nicht erstellt werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
