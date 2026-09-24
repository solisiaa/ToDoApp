import SwiftUI

// MARK: - TaskFormFields
// Общая форма «название + описание + дедлайн + приоритет» для Add/Edit.
// Вынесена в отдельный View, чтобы не дублировать разметку в двух экранах.
// Валидация: кнопка сохранения дизейблится при пустом title (trim),
// дублируя проверку RepositoryError.emptyTitle на уровне UI.
// Зависимости: SwiftUI, Models (Priority).

struct TaskFormFields: View {
    @Binding var title: String
    @Binding var details: String
    @Binding var hasDueDate: Bool
    @Binding var dueDate: Date
    @Binding var priority: Priority

    /// true, когда форму можно сохранять (непустой title).
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
