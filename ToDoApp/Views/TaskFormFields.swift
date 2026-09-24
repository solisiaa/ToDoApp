import SwiftUI

// MARK: - TaskFormFields (общая форма для Add/Edit)

struct TaskFormFields: View {
    @Binding var title: String
    @Binding var details: String
    @Binding var hasDueDate: Bool
    @Binding var dueDate: Date
    @Binding var priority: Priority

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Задача") {
                TextField("Название", text: $title)
                TextField("Описание (необязательно)", text: $details, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Срок") {
                Toggle("Дедлайн", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Дата", selection: $dueDate, displayedComponents: .date)
                }
            }

            Section("Приоритет") {
                Picker("Приоритет", selection: $priority) {
                    ForEach(Priority.allCases) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
