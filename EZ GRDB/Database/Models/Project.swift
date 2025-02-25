import Foundation
import GRDB

struct Project: Equatable {
    var id: Int64?
    var name: String
    var dueDate: Date
    var priority: Int
}

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
