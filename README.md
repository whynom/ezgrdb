#  <#GRDB the _EZ_ way#>

Here's some stuff

## An app from ground up, step by step
The motivation for making this app is to build a very simple app similar to the one in the GRDB repo, but step by step to hopefully show what everything is doing.  Hopefully, I, or anyone else, will be able to follow along with this whenever they are setting up a new app and need to get a good GRDB backed persistence model going.

### Making a functioning test file 
Add the following imports to your test file

``` swift
import Testing
import GRDB
import Foundation
@testable import EZ_GRDB
```

You'll be immediately be addressed with a very sensible error saying you don't have the GRDB package installed because you don't!  Let's add it now.

The dependency can be added to the project in XCode by going to

`File -> Add package dependency`

Enter the github url for the package in the search bar and install https://github.com/groue/GRDB.swift

While that adds the package to your project, it's still not added to your testing target.  Go into the app project and add it under `Frameworks and Libraries` for your testing target.

Your error is now gone and we can start writing tests.

#### A test for tasks
I want to show how to save data with a string, a date and a number, so I'm choosing to make a _project_.  Hopefully, we'll be able to attach tasks to that project to show to connect two tables together eventually.

Let's get our first test that inserts a `Project` into our database.

``` swift
struct EZ_GRDBTests {

    @Test func insert() throws {
        // Given an empty database
        let appDatabase = try makeEmptyTestDatabase()
        
        // When we insert a project
        var insertedProject = Project(name: "Build a house", dueDate: Date(), priority: 1000)
        try appDatabase.saveProject(&insertedProject)
        
        // Then the inserted project has an id
        #expect(insertedProject.id != nil)
        
        // Then the inserted project exists in the database
        let fetchedProject = try appDatabase.reader.read(Project.fetchOne)
        #expect(fetchedProject == insertedProject)
    }

}
```

This gives some errors having to do with the fact that
1. We don't have a `Project` model.
2. We don't have a a database

Let's deal with the `Project` model first.

##### Project model
Within our top app directory add a directory called `Database`. Within that folder make another folder called `Models`.  Finally, within that `Models` add a swift file called `Project`.  Add the following to that file.

``` swift
import Foundation

struct Project: Equatable {
    var id: Int64?
    var name: String
    var dueDate: Date
    var priority: Int
}
```

A simple straightforward model to use to make and use `Project`s, and we've taken care of one of the problems with our test.

- [ ] Explain why `Equatable`.
- [ ] Explain why the id is an optional.

##### AppDatabase
Now more to the point, we're going to start defining the actual database.  The two spots we're failing in our test is in the _making_ of the database and the _reading_ of the database.  Let's see if we can't fix those problems.

Let's add a new swift file to the `Database` folder called `AppDatabase` and within that file add the following code.

``` swift
import Foundation
import GRDB
import os.log

final class AppDatabase: Sendable {
    private let dbWriter: any DatabaseWriter
    
    init(_ dbWriter: any GRDB.DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
}
```

Just adding those imports, you'll run into an error about importing the `GRDB` library.  Remember to add the framework to your actual app target the same way you did for your app tests.

Here we're initializing our database with a `dbWriter` so we can start a `migrator`, but we have an error involving that `migrator` because we need to define it.  Define it with the following code to be inserted within the `AppDatabase` scope.

``` swift
...
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "player") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("score", .integer).notNull()
            }
        }
        
        return migrator
    }
...
```

When we initiate `migrator` we start a version of the database with the player table.  We can later add more versions of this table or even add new tables to our database later to update our app as we update it's capabilites.

For more information on what we're doing, check out the following in the GRDB documentation.

[databse connections](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections)
[migrations](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations)
[Erase database on schema](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations#The-eraseDatabaseOnSchemaChange-Option)
[database schema](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschema)

- [ ] What is the method `migrate` that depends on a `dbWriter`?
- [ ] Is the `registerMigration` method making a new database if a previous one doesn't exist?
