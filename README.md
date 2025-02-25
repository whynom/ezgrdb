# GRDB the _EZ_ way

GRDB felt pretty overwhelming when I was first confronted with it, but it also looked very promising.  After _barely_ squeezing the basics out of `Core Data` and `Swift Data` I realized that while they had an easy learning curve, whenever a problem arose it was a big hassle to fix because I didn't know what was going on.

My hopes are that GRDB might be a little more difficult to learn, but in the end, because I understand what is going on, it will be a lot more flexible and fixable.  This repo is an attempt to get a basic understanding of what is going on to get a pretty simple database up and running with some explanation.

## An app from ground up, step by step
The motivation for making this app is to build a very simple app like the [GRDB Demo App](https://github.com/groue/GRDB.swift/tree/master/Documentation/DemoApps/GRDBDemo), but step by step to show what everything is doing as well extending it a little bit with things like `Date`s and connecting various models together.  Hopefully, I, or anyone else, will be able to follow along with this whenever they are setting up a new app and need to get a good GRDB backed persistence model going.

## Making a functioning test file 
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
    
### A test for tasks
I want to show how to save data with a string, a date and a number, so I'm choosing to make a _project_.  Hopefully, we'll be able to attach tasks to that project to show how to connect two tables together eventually.

Let's get our first test that inserts a `Project` into our database.

``` swift
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

```

This gives some errors having to do with the fact that
1. We don't have a `Project` model.
2. We don't have a a database and its corresponding methods to make a configuration.

Let's deal with the `Project` model first.
    
### Project model
Within our top app directory add a directory called `Database`. Within that folder make another folder called `Models`.  Finally, within that `Models` directry add a swift file called `Project`.  Add the following to that file.

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

### AppDatabase
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
            try db.create(table: "project") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("dueDate", .text).notNull()
                t.column("priority", .integer).notNull()
            }
        }
        
        return migrator
    }
...
```

When we initiate `migrator` we start a version of the database with the player table.  We can later add more versions of this table or even add new tables to our database later to update our app as we update it's capabilities.

For more information on what we're doing, check out the following in the GRDB documentation.

1. [databse connections](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections)

2. [migrations](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations)

3. [Erase database on schema](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations#The-eraseDatabaseOnSchemaChange-Option)

4. [database schema](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschema)


- [ ] What is the method `migrate` that depends on a `dbWriter`?
- [ ] Is the `registerMigration` method making a new database if a previous one doesn't exist?

### Config, Read and Save.

1. Making a configuration
We're going to add an extension on `AppDatabase` below our prior definition of the class.  I'm making this an extension as this is how they made GRDB demo app. I believe it makes the code more organized and easier to understand.

``` swift
// MARK: - Database Configuration
extension AppDatabase {
    static func makeConfiguration(_ config: Configuration = Configuration()) -> Configuration {
        
        return config
    }
}
```

2. Reader
Add the following in a new extension below our configuration `AppDatabase` extension.

``` swift
// MARK: - Database Configuration
extension AppDatabase {
    var reader: any GRDB.DatabaseReader {
        dbWriter
    }
}
```

Thankfully, we get no errors with this code.

3. Save

   [GRDB Demo App](https://github.com/groue/GRDB.swift/tree/master/Documentation/DemoApps/GRDBDemo) which I'm following pretty closely here.

``` swift
// MARK: - Database Access: Reads
extension AppDatabase {
    func saveProject(_ project: inout Project) throws {
        try dbWriter.write { db in
            try project.save(db)
        }
    }
    
}
```

### Update the `Project` model.

Let's try to fix some of our errors.  We have no method `save` for our `Project` type.  We'll add a the `MutablePersistableRecord` to give us this saving function as well as `Codable` and `FetchableRecord`.  A the same time we'll define the columns and `didInsert` method.  Put the following code an extension below the original `Project` definition in the `Project` file we created earlier.

``` swift
extension Project: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let name = Column(CodingKeys.name)
        static let dueDate = Column(CodingKeys.dueDate)
        static let priority = Column(CodingKeys.priority)
    }
    
        mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
```

Making `Project` conform to the `Codable` `FetchableRecord` and `MutablePersistableRecord` allow the storing and reading of the model into SQLite rows.


### What we've done
At this point the tests pass!

This is extremely minimal, but we can now make a database, add to it, and read from it.  Not bad!

### Updating test.
Put the following test into the `EZ_GRDBTests` struct scope

``` swift
struct EZ_GRDBTests {
...
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
...
}
```

Test passes!

### Delete all
Let's make a test for deleting all `Project`s.  Add the following to the `EZ_GRDBTests` struct we've been putting all our tests in.

``` swift
struct EZ_GRDBTests {
...
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
...
}
```

This will give us an error about `AppDatabase` not having a `deleteAllProjects` function as we haven't defined it yet.  Let's do that now.

We'll put the following function in the writes `AppDatabase` extension.

``` swift
// MARK: - Database Access: Writes
extension AppDatabase {
...
    func deleteAllProjects() throws {
        try dbWriter.write { db in
            _ = try Project.deleteAll(db)
        }
    }

}
```

### `EZ_GRDBTests` finished
We've finished up all our tests for the basic functionality of our GRDB database.  We've got tests and functions that allow us to make a database, add a row, update a row and delete all the contents of a database.  Now we're going to move on to our `ProjectListModelTests`.  Make a new test file called `ProjectListModelTests` and make a struct called the same.  This test file should be in our `EZ GRDBTests` folder.

## Observation that gets current database
Our first test will be for observing a database's current state.  Put the following into the new file we've made.

``` swift
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
        model.observePlayers()
        
        // Then the model eventually has one player.
        try await pollUntil { model.players.count == 1 }
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
```

We'll get an error where we try to create a `ProjectListModel`.  Let's create a new file called `ProjectListModel` and put it in a new folder called `Views`.

### `ProjectListModel`

``` swift
import Foundation
import Observation
import GRDB

@Observable @MainActor final class ProjectListModel {
    
    private let appDatabase: AppDatabase
    @ObservationIgnored private var cancellable: AnyDatabaseCancellable?

    init(appDatabase: AppDatabase) {
        self.appDatabase = appDatabase
    }
}
```

tests has an error at `model.observeProjects`
add in

``` swift
    /// Start observing the database.
    func observeProjects() {
        cancellable = observation.start(in: appDatabase.reader) { error in
            // Handle error
        } onChange: { [unowned self] projects in
            self.projects = projects
        }
    }
```

This errors because there is no `observation` var.  What confuses me is that we observe the database only when we change the ordering.  That doesn't seem constant, I feel like you'd want to observe whenever there was a change to the database as well.  Would the list not change when a new item is added?  Why would you only want to check the database when the ordering changes?  Either way we need to add the ordering enum, the observation var and the observation in he observeProjects function.  first add the observation to observeProjects.

Update the `observeProejects` to the following:

``` swift
    /// Start observing the database.
    func observeProjects() {
        let observation = ValueObservation.tracking { [ordering] db in
            switch ordering {
            case .byName:
                try Project.all().orderedByName().fetchAll(db)
            case .byDueDate:
                try Project.all().orderedByDueDate().fetchAll(db)
            case .byPriority:
                try Project.all().orderedByDuePriority().fetchAll(db)
            }
            
        }

        
        cancellable = observation.start(in: appDatabase.reader) { error in
            // Handle error
        } onChange: { [unowned self] projects in
            self.projects = projects
        }
    }
```

The problem now is we don't have the `orderedByName` method, or any of the other similar methods like that.  We'll add them just as they did in the demo app.

We make these methods by writing an extension on `DerivableRequest<Project>` add the following to the bottom of the `Project` file.

``` swift
private typealias Columns = Project.Columns

extension DerivableRequest<Project> {
    func orderedByName() -> Self {
        order(Columns.name.collating(.localizedCaseInsensitiveCompare))
    }
    
    func orderedByDueDate() -> Self {
        order(
            Columns.dueDate.desc,
            Columns.dueDate.collating(.localizedCaseInsensitiveCompare))
    }
    
    func orderedByPriority() -> Self {
        order(
            Columns.priority.desc,
            Columns.priority.collating(.localizedCaseInsensitiveCompare))
    }
}
```

I don't know what `DerivableRequest` is, other than a protocol with some functions.  Here, we're adding those functions.  When we get all of the project using the `all` method on a `Project` we can run these `orderedBy` methods to fetch the whole database.  The `all` method returns a ` QueryInterfaceRequest<Project>` type, which I guess we can run a `DerivableRequest` function on.  Not exactly sure how.

Either way, we need the ordering variable and enum added to our `ProjectListModel`.  Put this at the top of the class definition

``` swift
    enum Ordering {
        case byName
        case byDueDate
        case byPriority
    }

    var ordering = Ordering.byPriority {
        didSet { observeProjects() }
    }
```

Just adding that not only does our app build, it also passes our first test we put in.  I still haven't added all the methods that are under the Actions section in the demo app.  The `deletePlayers`, `deleteAllPlayers`, `refreshPlayers`, `refreshPlayersManyTimes` methods.  I won't add them until I need to

###  Testing that the observation grabs database changes
We throw this second test in, and all passes.

``` swift
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
```

### Test that we delete all projects
Put this as the final test before the `pollUntil` function.

``` swift
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
```

We get an error because we don't have `deleteAllProjects`.  I'm tempted to add all of those methods to `ProjectListModel` but I won't because I want to see where those other methods are used.  Probably inthe UI somehwere.

Let's add the methods we need to the end `PlayerListModel` and mark the section actions.

``` swift
    // MARK: - Actions
    /// Delete all projects.
    func deleteAllProjects() throws {
        try appDatabase.deleteAllProjects()
    }
```

We are passing all the tests now.  I really want to note that I did _not_ put in all the other methods into the `PlayerListModel`.  These methods just take wahtever database you gave the `PlayerListModel` you made and runs the methods that we described in the `AppDatabase` that we made.  I guess they're kind of wrappers so we can deal with `PlayerListModel` without having to fuss with the `AppDatabase` directly.
