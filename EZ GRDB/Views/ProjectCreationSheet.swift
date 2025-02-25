import SwiftUI

/// A view that creates a `Project`. Display it as a sheet.
struct ProjectCreationSheet: View {
    @Environment(\.appDatabase) var appDatabase
    @Environment(\.dismiss) var dismiss
    @State var form = ProjectForm(name: "", dueDate: Date(), priority: 3)
    
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
        var project = Project(name: form.name, dueDate: form.dueDate, priority: 3)
        try? appDatabase.saveProject(&project)
        dismiss()
    }
}

// MARK: - Previews

#Preview {
    ProjectCreationSheet()
}
