import SwiftUI

/// A view that edits a `ProjectForm`.
struct ProjectFormView: View {
    @Binding var form: ProjectForm
    
    private enum FocusElement {
        case name
        case dueDate
        case priority
    }
    @FocusState private var focusedElement: FocusElement?
    
    var body: some View {
        Group {
            LabeledContent {
                TextField(text: $form.name) { EmptyView() }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedElement, equals: .name)
                    .labelsHidden()
                    .onSubmit {
                        focusedElement = .dueDate
                    }
            } label: {
                Text("Name").foregroundStyle(.secondary)
            }
            
            DatePicker("Due Date", selection: $form.dueDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
            //                .padding()
            
            Picker("Choose Number", selection: $form.priority) {
                ForEach(1...5, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
        }
        .onAppear { focusedElement = .name }
    }
}

/// The model edited by `PlayerFormView`.
struct ProjectForm {
    var name: String
    var dueDate: Date
    var priority: Int
}

// MARK: - Previews

#Preview("Prefilled") {
    @Previewable @State var form = ProjectForm(name: "Build A House", dueDate: Date(), priority: 3)
    
    Form {
        ProjectFormView(form: $form)
    }
}

#Preview("Empty") {
    @Previewable @State var form = ProjectForm(name: "", dueDate: Date(), priority: 1)
    
    Form {
        ProjectFormView(form: $form)
    }
}
