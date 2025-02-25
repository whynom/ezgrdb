import Foundation
import Observation
import GRDB

@Observable @MainActor final class ProjectListModel {
    
    enum Ordering {
        case byName
        case byDueDate
        case byPriority
    }

    var ordering = Ordering.byPriority {
        didSet { observeProjects() }
    }

    var projects: [Project] = []

    private let appDatabase: AppDatabase
    @ObservationIgnored private var cancellable: AnyDatabaseCancellable?

    init(appDatabase: AppDatabase) {
        self.appDatabase = appDatabase
    }
    
    
    /// Start observing the database.
    func observeProjects() {
        let observation = ValueObservation.tracking { [ordering] db in
            switch ordering {
            case .byName:
                try Project.all().orderedByName().fetchAll(db)
            case .byDueDate:
                try Project.all().orderedByDueDate().fetchAll(db)
            case .byPriority:
                try Project.all().orderedByPriority().fetchAll(db)
            }
            
        }

        
        cancellable = observation.start(in: appDatabase.reader) { error in
            // Handle error
        } onChange: { [unowned self] projects in
            self.projects = projects
        }
    }
    
    
    // MARK: - Actions
    /// Delete players at specified indexes in `self.players`.
    func deleteProjects(at offsets: IndexSet) throws {
        let projectIds = offsets.compactMap { projects[$0].id }
        try appDatabase.deleteProjects(ids: projectIds)
    }

    /// Delete all projects.
    func deleteAllProjects() throws {
        try appDatabase.deleteAllProjects()
    }
}

