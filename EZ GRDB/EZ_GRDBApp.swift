import SwiftUI

@main
struct EZ_GRDBApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectsNavigationView().appDatabase(.shared)
        }
    }
}

// MARK: - Give SwiftUI access to the database

extension EnvironmentValues {
    @Entry var appDatabase = AppDatabase.empty()
}

extension View {
    func appDatabase(_ appDatabase: AppDatabase) -> some View {
        self.environment(\.appDatabase, appDatabase)
    }
}
