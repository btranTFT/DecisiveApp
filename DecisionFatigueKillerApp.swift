import SwiftUI
import SwiftData

@main
struct DecisionFatigueKillerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            OptionItem.self,
            PickHistory.self,
            Settings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Seed data safely on Main Actor
                    DataController.seedCategories(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
