import Foundation

// MARK: - MockTaskRepository (in-memory, для Preview и тестов)

@MainActor
final class MockTaskRepository: TaskRepositoryProtocol {
    var storedTasks: [Task] = []
    var shouldFail = false
    var mockError: Error = RepositoryError.underlying(
        NSError(domain: "Mock", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock-ошибка"])
    )

    init(tasks: [Task] = []) {
        self.storedTasks = tasks
    }

    func fetch(filter: TaskFilter) throws -> [Task] {
        if shouldFail { throw mockError }
        let sorted = storedTasks.sorted { $0.createdAt > $1.createdAt }
        switch filter {
        case .all:
            return sorted
        case .active:
            return sorted.filter { !$0.isCompleted }
        case .completed:
            return sorted.filter { $0.isCompleted }
        }
    }

    @discardableResult
    func create(
        title: String,
        details: String,
        dueDate: Date?,
        priority: Priority,
        category: Category?
    ) throws -> Task {
        if shouldFail { throw mockError }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.emptyTitle }
        let task = Task(title: trimmed, details: details, dueDate: dueDate, priority: priority)
        storedTasks.append(task)
        return task
    }

    func update(_ task: Task) throws {
        if shouldFail { throw mockError }
        guard storedTasks.contains(where: { $0.id == task.id }) else {
            throw RepositoryError.underlying(
                NSError(domain: "Mock", code: 404, userInfo: [NSLocalizedDescriptionKey: "Задача не найдена"])
            )
        }
        let trimmed = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.emptyTitle }
        task.title = trimmed
    }

    func toggleCompletion(_ task: Task) throws {
        if shouldFail { throw mockError }
        task.isCompleted.toggle()
    }

    func delete(_ task: Task) throws {
        if shouldFail { throw mockError }
        storedTasks.removeAll { $0.id == task.id }
    }
}
