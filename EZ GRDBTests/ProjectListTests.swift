import Testing
import GRDB
import Foundation
@testable import EZ_GRDB

struct ProjectListTests {
    
    // MARK: - PlayerListModel.observePlayers tests
    @Test(.timeLimit(.minutes(1)))
    @MainActor func observation_grabs_current_database_state() async throws {
        // Given a PlayerListModel on a database that contains one player
        let appDatabase = try makeEmptyTestDatabase()
        var project = Project(name: "Build a house",
                             dueDate: staticDate(),
                             priority: 1)
        try appDatabase.saveProject(&project)
        let model = ProjectListModel(appDatabase: appDatabase)
        
        // When the model starts observing the database
        model.observeProjects()
        
        // Then the model eventually has one player.
        try await pollUntil { model.projects.count == 1 }
    }
    
    @Test(.timeLimit(.minutes(1)))
    @MainActor func observation_grabs_database_changes() async throws {
        // Given a PlayerListModel that has one project
        let appDatabase = try makeEmptyTestDatabase()
        var project1 = Project(name: "Build a house",
                             dueDate: staticDate(),
                             priority: 1)
        try appDatabase.saveProject(&project1)
        let model = ProjectListModel(appDatabase: appDatabase)
        model.observeProjects()
        try await pollUntil { model.projects.count == 1 }
        
        // When we insert a second project
        var project2 = Project(name: "Build a farm",
                             dueDate: staticDate(),
                             priority: 3)
        try appDatabase.saveProject(&project2)
        
        // Then the model eventually has two players.
        try await pollUntil { model.projects.count == 2 }
    }
    
    
    @Test
    @MainActor func test_deleteAllProjects_deletes_projects_in_the_database() async throws {
        // Given a ProjectListModel on a database that contains a project
        let appDatabase = try makeEmptyTestDatabase()
        var project = Project(name: "Build a house",
                             dueDate: staticDate(),
                             priority: 1)
        try appDatabase.saveProject(&project)
        let model = ProjectListModel(appDatabase: appDatabase)
        
        // When we delete all projects
        try model.deleteAllProjects()
        
        // Then the database is empty.
        let playerCount = try await appDatabase.reader.read { db in
            try Project.fetchCount(db)
        }
        #expect(playerCount == 0)
    }

    /// Convenience method that loops until a condition is met.
    private func pollUntil(condition: @escaping @MainActor () async -> Bool) async throws {
        try await confirmation { confirmation in
            while true {
                if await condition() {
                    confirmation()
                    return
                } else {
                    try await Task.sleep(for: .seconds(0.01))
                }
            }
        }
    }
    
}
