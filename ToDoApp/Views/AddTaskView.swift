import SwiftUI

// MARK: - AddTaskView

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TaskListViewModel

    @State private var title = ""
    @State private var details = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: Priority = .medium

    var body: some View {
        NavigationStack {
            TaskFormFields(
                title: $title,
                details: $details,
                hasDueDate: $hasDueDate,
                dueDate: $dueDate,
                priority: $priority
            )
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        viewModel.addTask(
                            title: title,
                            details: details,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority
                        )
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    AddTaskView(viewModel: TaskListViewModel(repository: MockTaskRepository()))
}
