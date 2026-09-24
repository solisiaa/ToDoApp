import Foundation
import SwiftData

// MARK: - Priority
// Приоритет — обычный Codable-enum с Int rawValue.
// Хранится в SwiftData как примитив, не требует отдельной таблицы.
// Решение: enum вместо @Model — KISS, сортировка/фильтрация по rawValue тривиальны.

enum Priority: Int, Codable, CaseIterable, Identifiable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }

    /// Человекочитаемое название для Picker и accessibility.
    var displayName: String {
        switch self {
        case .low: "Низкий"
        case .medium: "Средний"
        case .high: "Высокий"
        }
    }
}

// MARK: - Category
// Опциональная сущность из ТЗ: отношение one-to-many Task -> Category.
// Удаление категории каскадно удаляет её задачи (.cascade).

@Model
final class Category {
    var name: String
    var createdAt: Date

    /// Обратная сторона связи. Cascade: удаление Category удаляет все её Task.
    @Relationship(deleteRule: .cascade, inverse: \Task.category)
    var tasks: [Task]?

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}

// MARK: - Task
// Главная @Model-сущность. `final class` обязателен для SwiftData.
// id имеет default — объект идентифицируем сразу после init, до сохранения в контекст.
// externalStorage для details не нужен — короткие строки храним inline.

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var priorityRawValue: Int

    /// Опциональная связь с категорией. Nullify неявно: удаление Task не трогает Category.
    /// NB: inverse указан только на стороне Category — двусторонний inverse
    /// вызывает circular reference в макросе @Relationship на этом тулчейне.
    var category: Category?

    /// Типобезопасная обёртка над хранимым Int. Не персистентна сама по себе.
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
