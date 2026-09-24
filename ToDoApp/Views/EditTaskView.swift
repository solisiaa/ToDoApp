import SwiftUI

// MARK: - EditTaskView

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TaskListViewModel
    let task: Task

    @State private var title: String
    @State private var details: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var priority: Priority
    @State private var isShowingDeleteConfirm = false

    init(viewModel: TaskListViewModel, task: Task) {
        self.viewModel = viewModel
        self.task = task
        _title = State(initialValue: task.title)
        _details = State(initialValue: task.details)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _priority = State(initialValue: task.priority)
    }

    var body: some View {
        NavigationStack {
            VStack {
                TaskFormFields(
                    title: $title,
                    details: $details,
                    hasDueDate: $hasDueDate,
                    dueDate: $dueDate,
                    priority: $priority
                )

                Button(role: .destructive) {
                    isShowingDeleteConfirm = true
                } label: {
                    Label("Удалить задачу", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding()
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        viewModel.applyEdit(
                            to: task,
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
            .confirmationDialog(
                "Удалить задачу?",
                isPresented: $isShowingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    viewModel.delete(task)
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие нельзя отменить.")
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    EditTaskView(
        viewModel: TaskListViewModel(repository: MockTaskRepository()),
        task: Task(title: "Пример", details: "Описание", priority: .high)
    )
}
