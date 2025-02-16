import Testing
import GRDB
import Foundation
@testable import EZ_GRDB

struct EZ_GRDBTests {

    @Test func insert() throws {
        let components = DateComponents(calendar: Calendar.current, year: 2020, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let staticDate = components.date!

        
        // Given an empty database
        let appDatabase = try makeEmptyTestDatabase()
        
        // When we insert a project
        var insertedProject = Project(name: "Build a house", dueDate: staticDate, priority: 1000)
        try appDatabase.saveProject(&insertedProject)
        
        // Then the inserted project has an id
        #expect(insertedProject.id != nil)
        
        // Then the inserted project exists in the database
        let fetchedProject = try appDatabase.reader.read(Project.fetchOne)
        #expect(fetchedProject == insertedProject)
    }

    /// Return an empty, in-memory, `AppDatabase`.
    private func makeEmptyTestDatabase() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        return try AppDatabase(dbQueue)
    }
}
