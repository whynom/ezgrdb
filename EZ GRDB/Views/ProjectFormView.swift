import SwiftUI

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
                        focusedElement = .name
                    }
            } label: {
                Text("Name").foregroundStyle(.secondary)
            }
            
            LabeledContent {
                DatePicker("Due Date", selection: $form.dueDate)
                    .focused($focusedElement, equals: .dueDate)
                    .labelsHidden()
            } label: {
                Text("Due").foregroundStyle(.secondary)
            }
            
            LabeledContent {
                Picker("Select a Number", selection: $form.priority) {
                    ForEach(1...5, id: \.self) { number in
                        Text("\(number)").tag(number)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

            } label: {
                Text("Priority").foregroundStyle(.secondary)
            }
        }
        .onAppear { focusedElement = .name }
    }
}

struct ProjectForm {
    var name: String
    var dueDate: Date
    var priority: Int
    
}

#Preview("Prefilled") {
    @Previewable @State var form = ProjectForm(name: "Build a house", dueDate: .now.addingTimeInterval(240000), priority: 3)
    
    Form {
        ProjectFormView(form: $form)
    }
}
