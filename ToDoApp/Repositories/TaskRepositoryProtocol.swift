import Foundation

// MARK: - TaskFilter

enum TaskFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Все"
    case active = "Активные"
    case completed = "Выполненные"

    var id: String { rawValue }
}

// MARK: - TaskRepositoryProtocol

protocol TaskRepositoryProtocol: Sendable {
    func fetch(filter: TaskFilter) throws -> [Task]
    @discardableResult
    func create(
        title: String,
        details: String,
        dueDate: Date?,
        priority: Priority,
        category: Category?
    ) throws -> Task
    func update(_ task: Task) throws
    func toggleCompletion(_ task: Task) throws
    func delete(_ task: Task) throws
}

// MARK: - RepositoryError

enum RepositoryError: LocalizedError {
    case emptyTitle
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            "Название задачи не может быть пустым."
        case .underlying(let error):
            "Ошибка сохранения: \(error.localizedDescription)"
        }
    }
}
