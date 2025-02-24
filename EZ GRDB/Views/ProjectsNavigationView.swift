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
        .sheet(isPresented: $presentsCreationSheet) {
            ProjectCreationSheet()
        }
    }
}

#Preview {
    ProjectsNavigationView()
}
