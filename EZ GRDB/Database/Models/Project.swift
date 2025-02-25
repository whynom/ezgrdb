import Foundation
import GRDB

struct Project: Equatable {
    var id: Int64?
    var name: String
    var dueDate: Date
    var priority: Int
}

extension Project {
    private static let names = [
        "Todo List", "Weather App", "Calculator", "Recipe Finder", "Chat Application", "Expense Tracker", "Fitness Tracker", "Music Player", "Photo Gallery", "Game Scoreboard", "Currency Converter", "News Aggregator", "Language Learning Tool", "Memory Game", "Travel Planner"
    ]

    
    /// Creates a new project with random name and random score
    static func makeRandom() -> Project {
        Project(id: nil, name: randomName(), dueDate: randomDate(), priority: Int.random(in: 1...5))
    }
    
    /// Returns a random name
    static func randomName() -> String {
        names.randomElement()!
    }
    
    /// Returns a random score
    static func randomDate() -> Date {
        Date().addingTimeInterval(Double.random(in: -99999...99999999))
    }
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
