import SwiftUI

// MARK: - TaskRowView
// Глупая (dumb) строка списка: только отображает Task и пробрасывает
// действия наверх через замыкания. Никаких обращений к ViewModel/Repository —
// это сохраняет иерархию View → ViewModel → Repository.
// Цветовая индикация приоритета: синий / оранжевый / красный.
// Выполненные задачи — strikethrough + приглушённый цвет.
// Зависимости: SwiftUI, Models (Task, Priority).

struct TaskRowView: View {
    let task: Task
    var onToggle: () -> Void
    var onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Кнопка-чекбокс: тап инвертирует isCompleted через ViewModel.
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : priorityColor)
                    .accessibilityLabel(task.isCompleted ? "Отметить как невыполненную" : "Отметить как выполненную")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    // Strikethrough для выполненных — требование ТЗ.
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    // Бейдж приоритета цветом.
                    Label(task.priority.displayName, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(priorityColor)

                    if let dueDate = task.dueDate {
                        Label {
                            Text(dueDate, format: .dateTime.day().month().year())
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        // Тап по строке открывает редактирование.
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .combine)
    }

    // MARK: Helpers

    private var priorityColor: Color {
        switch task.priority {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }

    /// Просрочка: есть дедлайн в прошлом и задача не выполнена.
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
}

#Preview {
    List {
        TaskRowView(
            task: Task(title: "Купить молоко", details: "2 пакета", dueDate: .now, priority: .high),
            onToggle: {},
            onEdit: {}
        )
        TaskRowView(
            task: Task(title: "Готово", isCompleted: true, priority: .low),
            onToggle: {},
            onEdit: {}
        )
    }
}
