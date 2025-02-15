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
                t.column("dueDate", .text).notNull()
                t.column("priority", .integer).notNull()
            }
        }
        
        return migrator
    }
    
}

extension AppDatabase {
    func saveProject(_ project: inout Project) throws {
        try dbWriter.write { db in
            try project.save(db)
        }
    }
    
}

extension AppDatabase {
    static func makeConfiguration(_ config: Configuration = Configuration()) -> Configuration {
        
        return config
    }
}

extension AppDatabase {
    var reader: any GRDB.DatabaseReader {
        dbWriter
    }
}
