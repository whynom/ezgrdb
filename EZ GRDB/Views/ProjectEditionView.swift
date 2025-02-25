import SwiftUI

struct ProjectEditionView: View {
    @Environment(\.isPresented) var isPresented
    @Environment(\.appDatabase) var appDatabase
    @State var form: ProjectForm
    var project: Project
    
    init(project: Project) {
        self.project = project
        self._form = State(initialValue: ProjectForm(name: project.name, dueDate: Date(), priority: 3))
    }
    
    var body: some View {
        Form {
            ProjectFormView(form: $form)
        }
        .navigationTitle(project.name)
        .onChange(of: isPresented) {
            if !isPresented {
                // Back button was pressed
                save()
            }
        }
    }
    
    private func save() {
        var project = project
        project.name = form.name
        project.dueDate = form.dueDate
        project.priority = form.priority
        try? appDatabase.saveProject(&project)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProjectEditionView(project: .makeRandom())
    }
}
