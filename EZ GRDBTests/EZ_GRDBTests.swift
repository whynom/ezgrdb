import Testing
import GRDB
import Foundation
@testable import EZ_GRDB

struct EZ_GRDBTests {

    @Test func insert() throws {
        // Given an empty database
        let appDatabase = try makeEmptyTestDatabase()
        
        // When we insert a project
        var insertedProject = Project(name: "Build a house", dueDate: staticDate(), priority: 1000)
        try appDatabase.saveProject(&insertedProject)
        
        // Then the inserted project has an id
        #expect(insertedProject.id != nil)
        
        // Then the inserted project exists in the database
        let fetchedProject = try appDatabase.reader.read(Project.fetchOne)
        #expect(fetchedProject == insertedProject)
    }
    
    @Test func update() throws {
        // Given a database that contains a player
        let appDatabase = try makeEmptyTestDatabase()
        var insertedProject = Project(name: "Build a house", dueDate: staticDate(), priority: 1000)
        try appDatabase.saveProject(&insertedProject)
        
        // When we update a player
        var updatedProject = insertedProject
        updatedProject.name = "Write a book"
        updatedProject.dueDate = staticDate().addingTimeInterval(86400)
        updatedProject.priority = 500
        try appDatabase.saveProject(&updatedProject)
        
        // Then the player is updated
        let fetchedProject = try appDatabase.reader.read(Project.fetchOne)
        #expect(fetchedProject == updatedProject)
    }
    
    @Test func deleteAll() throws {
        // Given a database that contains a player
        let appDatabase = try makeEmptyTestDatabase()
        var project = Project(name: "Build a house", dueDate: staticDate(), priority: 1000)
        try appDatabase.saveProject(&project)
        
        // When we delete all players
        try appDatabase.deleteAllProjects()
        
        // Then no player exists
        let count = try appDatabase.reader.read(Project.fetchCount(_:))
        #expect(count == 0)
    }

    
}


/// Return an empty, in-memory, `AppDatabase`.
func makeEmptyTestDatabase() throws -> AppDatabase {
    let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
    return try AppDatabase(dbQueue)
}

/// A static date for testing purposes
public func staticDate() -> Date {
    let components = DateComponents(calendar: Calendar.current, year: 2020, month: 1, day: 1, hour: 0, minute: 0, second: 0)
    return components.date!
}
