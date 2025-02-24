import SwiftUI

struct ProjectsNavigationView: View {
    @State var presentsCreationSheet = false
    @State var form = ProjectForm(name: "", dueDate: Date(), priority: 1)

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
            ProjectFormView(form: $form)
        }
    }
}

#Preview {
    ProjectsNavigationView()
}
