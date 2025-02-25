import SwiftUI

/// A view that displays a list of players.
struct ProjectListView: View {
    @Bindable var model: ProjectListModel
    
    var body: some View {
        List {
            ForEach(model.projects, id: \.id) { project in
                NavigationLink {
                    ProjectEditionView(project: project)
                } label: {
                    ProjectRow(project: project)
                }
            }
            .onDelete { offsets in
                try? model.deleteProjects(at: offsets)
            }
        }
        .animation(.default, value: model.projects)
        .listStyle(.plain)
        .navigationTitle("\(model.projects.count) Players")
    }
}

struct ProjectRow: View {
    var project: Project
    
    var body: some View {
        HStack {
            Group {
                if project.name.isEmpty {
                    Text("Anonymous").italic()
                } else {
                    Text(project.name)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(project.priority) priority")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview {
    struct Preview: View {
        @Environment(\.appDatabase) var appDatabase
        
        var body: some View {
            // This technique makes it possible to create an observable object
            // (PlayerListModel) from the SwiftUI environment.
            ContentView(appDatabase: appDatabase)
        }
    }
    
    struct ContentView: View {
        @State var model: ProjectListModel
        
        init(appDatabase: AppDatabase) {
            _model = State(initialValue: ProjectListModel(appDatabase: appDatabase))
        }

        var body: some View {
            NavigationStack {
                ProjectListView(model: model)
            }
            .onAppear { model.observeProjects() }
        }
    }
    
    return Preview().appDatabase(.random())
}
