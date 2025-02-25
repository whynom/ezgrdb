import Foundation
import GRDB
import os.log

final class AppDatabase: Sendable {
    private let dbWriter: any DatabaseWriter
    
    init(_ dbWriter: any GRDB.DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "project") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("dueDate", .date).notNull()
                t.column("priority", .integer).notNull()
            }
        }
        
        return migrator
    }
    
}


// MARK: - Database Configuration
extension AppDatabase {
    static func makeConfiguration(_ config: Configuration = Configuration()) -> Configuration {
        
        return config
    }
}

// MARK: - Database Access: Writes
extension AppDatabase {
    func saveProject(_ project: inout Project) throws {
        try dbWriter.write { db in
            try project.save(db)
        }
    }
    
    /// Delete the specified projects
    func deleteProjects(ids: [Int64]) throws {
        try dbWriter.write { db in
            _ = try Project.deleteAll(db, keys: ids)
        }
    }

    func deleteAllProjects() throws {
        try dbWriter.write { db in
            _ = try Project.deleteAll(db)
        }
    }
    
    /// Create random projects if the database is empty.
    func createRandomProjectsIfEmpty() throws {
        try dbWriter.write { db in
            if try Project.all().isEmpty(db) {
                try createRandomProjects(db)
            }
        }
    }
    
    /// Support for `createRandomProjectsIfEmpty()` and `refreshPlayers()`.
    private func createRandomProjects(_ db: Database) throws {
        for _ in 0..<8 {
            _ = try Project.makeRandom().inserted(db)
        }
    }

}

// MARK: - Database Access: Reads
extension AppDatabase {
    var reader: any GRDB.DatabaseReader {
        dbWriter
    }
}
