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

    /// Return an empty, in-memory, `AppDatabase`.
    private func makeEmptyTestDatabase() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        return try AppDatabase(dbQueue)
    }
    
    private func staticDate() -> Date {
        let components = DateComponents(calendar: Calendar.current, year: 2020, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        return components.date!
    }

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
We've finished up all our tests for the basic functionality of our GRDB database.  We've got tests and functions that allow us to make a database, add a row, update a row and delete all the contents of a database.  Now we're going to start building the user interface with `SwiftUI` and connecting our database to that so that our app will be usable.

## Setting up the user interface
You can't have an app without an interface, so let's start with our main app file.  There's going to be a lot of SwiftUI involved with little or no explanation because I'm mainly focused on the database. 

### App top level View
The boilerplate code that was given to us when we made the project works with one small change.  We're going to replace `ContentView()` with  `ProjectsNavigationView()`.  Replace `ContentView()` with  `ProjectsNavigationView()` and your main app file should look like the following.

``` swift
import SwiftUI

@main
struct EZ_GRDBApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectsNavigationView()
        }
    }
}
```

This will give an error about `ProjectsNavigationView` not existing because it doesn't, so let's start building that top level `View`

### `ProjectsNavigationView`
Let's start by making a `Views` folder within our main app folder.  Then we'll make a new `SwiftUI` file in that `Views` folder named `ProjectsNavigationView` and add the following code.

``` swift
import SwiftUI

struct ProjectsNavigationView: View {
    @State var presentsCreationSheet = false

    var body: some View {
        emptyProjectsView
    }
    
    private var emptyProjectsView: some View {
        ContentUnavailableView {
            Label("No Projects... yet", systemImage: "square.3.layers.3d.slash")
        } actions: {
            Button("Add Project") {
                presentsCreationSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ProjectsNavigationView()
}
```

This gives a pretty little view that shows we don't have any projects... yet.  Nothing much, but it's a start.

#### A `View` for creating a project
We're going to make a `ProjectFormView` for creating and editing `Project`s.  I'm just going to add all the code with no explanation because it's all SwiftUI.  Just slap this code in a new file you put in your `Views` folder with the name `ProjectFormView`.

``` swift
import SwiftUI

struct ProjectFormView: View {
    @Binding var form: ProjectForm
    
    private enum FocusElement {
        case name
        case dueDate
        case priority
    }
    @FocusState private var focusedElement: FocusElement?

    var body: some View {
        Group {
            LabeledContent {
                TextField(text: $form.name) { EmptyView() }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedElement, equals: .name)
                    .labelsHidden()
                    .onSubmit {
                        focusedElement = .name
                    }
            } label: {
                Text("Name").foregroundStyle(.secondary)
            }
            
            LabeledContent {
                DatePicker("Due Date", selection: $form.dueDate)
                    .focused($focusedElement, equals: .dueDate)
                    .labelsHidden()
            } label: {
                Text("Due").foregroundStyle(.secondary)
            }
            
            LabeledContent {
                Picker("Select a Number", selection: $form.priority) {
                    ForEach(1...5, id: \.self) { number in
                        Text("\(number)").tag(number)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

            } label: {
                Text("Priority").foregroundStyle(.secondary)
            }
        }
        .onAppear { focusedElement = .name }
    }
}

struct ProjectForm {
    var name: String
    var dueDate: Date
    var priority: Int
    
}

#Preview("Prefilled") {
    @Previewable @State var form = ProjectForm(name: "Build a house", dueDate: .now.addingTimeInterval(240000), priority: 3)
    
    Form {
        ProjectFormView(form: $form)
    }
}
```

### `ProjectCreationSheet`
We have a form, but what we really want is a something that houses that form and has save button and all that.  The form was just the inner part of the creation sheet.  Let's make a new `ProjectCreationSheet` file and put it in our `Views` folder.  Add this to that new file.

``` swift
import SwiftUI

/// A view that creates a `Player`. Display it as a sheet.
struct ProjectCreationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var form = ProjectForm(name: "", dueDate: Date(), priority: 1)
    
    var body: some View {
        NavigationStack {
            Form {
                ProjectFormView(form: $form)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
    }
    
    private func save() {
        dismiss()
    }
}

// MARK: - Previews

#Preview {
    ProjectCreationSheet()
}
```

This gives us our creation sheet, but we need to connect that with our `ProjectsNavigationView`.  This can be done by adding a `sheet` method onto our `emptyProjectsView` in our `ProjectsNavigationView` as follows.

``` swift
...
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $presentsCreationSheet) {
            ProjectCreationSheet()
        }
    }
...
```

So there we are with a considerable amount of UI under our belt, but what if we did have some `Project`s to show?  Where would we see them?  So far we only have a view for no projects.  Let's build our actual list of projects now.

### `ProjectListView`
We're going to make our list view that shows all our projects. It won't be connected to a database yet but we'll get to see our UI before diving into how to access a database. Create a new file in our `View` folder and call it `ProjectListView`







### Starting with an empty database at launch

Let's add this to our `EZ_GRDPApp` file

``` swift
// MARK: - Give SwiftUI access to the database

extension EnvironmentValues {
    @Entry var appDatabase = AppDatabase.empty()
}
```

This gives an error because we don't have an `empty` method defined on the `AppDatabase` type.  Let's do that now.

Rotely following the GRDBDemo app, we're going to put this in our `Persistance` file we will make now within our `Database` directory. In this new file put the following.

``` swift
extension AppDatabase {
    /// Creates an empty database for SwiftUI previews
    static func empty() -> AppDatabase {
        // Connect to an in-memory database
        let dbQueue = try! DatabaseQueue(configuration: AppDatabase.makeConfiguration())
        return try! AppDatabase(dbQueue)
    }
}
```

We're making a `DatabaseQueue` because it supports in-app memory databases which is what we're loading up here.  For information read [Database Connections](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections) in the documentation.

Now we're also going to make a method on the `View` type so that we can inject the database information into our top level view and have it available to all its child views throughout the app.

``` swift
extension View {
    func appDatabase(_ appDatabase: AppDatabase) -> some View {
        self.environment(\.appDatabase, appDatabase)
    }

```

We add this with no error or complaints from XCode and we have an environment variable that accesses our database at all levels of our app.
