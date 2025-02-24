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
