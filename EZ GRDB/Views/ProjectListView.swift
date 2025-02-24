import SwiftUI

struct ProjectListView: View {
    @State var projects: [ProjectTestable] = []
    var body: some View {
        List {
            ForEach(projects, id: \.id) { project in
                HStack {
                    Text(project.name)
                    Text("\(project.priority)")
                    Text("\(project.dueDate)")
                }
            }
            .onDelete { offsets in
            }
        }
        .animation(.default, value: projects)
        .listStyle(.plain)
        .navigationTitle("\(projects.count) Projects")
        .onAppear {
            projects = sixRandomProjects()
        }
    }
}

func sixRandomProjects() -> [ProjectTestable] {
    var projects: [ProjectTestable] = []
    for _ in 1..<6 {
        projects.append(randomProject())
    }
    return projects
}

func randomProject() -> ProjectTestable {
    ProjectTestable(name: randomProjectName(),
            dueDate: Date().addingTimeInterval(Double.random(in: 0...999999)),
            priority: Int.random(in: 1...5))
}

func randomProjectName() -> String {
    let names: [String] = ["Todo List", "Weather App", "Calculator", "Recipe Finder", "Chat Application", "Expense Tracker", "Fitness Tracker", "Music Player", "Photo Gallery", "Game Scoreboard", "Currency Converter", "News Aggregator", "Language Learning Tool", "Memory Game", "Travel Planner"]
    return names.randomElement() ?? "Couldn't get a random name"
}

#Preview {
    ProjectListView()
}
