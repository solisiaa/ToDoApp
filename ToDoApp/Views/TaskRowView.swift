import SwiftUI

// MARK: - TaskRowView

struct TaskRowView: View {
    let task: Task
    var onToggle: () -> Void
    var onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
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
