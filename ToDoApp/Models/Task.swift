import Foundation
import SwiftData

// MARK: - Priority

enum Priority: Int, Codable, CaseIterable, Identifiable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .low: "Низкий"
        case .medium: "Средний"
        case .high: "Высокий"
        }
    }
}

// MARK: - Category

@Model
final class Category {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Task.category)
    var tasks: [Task]?

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}

// MARK: - Task

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var priorityRawValue: Int

    // inverse только с одной стороны — двусторонний ломает макрос @Relationship
    var category: Category?

    @Transient
    var priority: Priority {
        get { Priority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        priority: Priority = .medium,
        category: Category? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.priorityRawValue = priority.rawValue
        self.category = category
    }
}
