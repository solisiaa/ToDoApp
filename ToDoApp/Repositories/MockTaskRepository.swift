import Foundation

// MARK: - MockTaskRepository
// In-memory реализация протокола для SwiftUI Preview и unit-тестов
// (тесты видят её через @testable import ToDoApp).
// Хранит задачи в обычном массиве — никакого SwiftData, никаких контейнеров.
// Флаги shouldFail* позволяют тестировать ветку ошибок ViewModel (errorMessage).
// Лежит в app-target осознанно: Preview компилируется вместе с приложением.
// Зависимости: только Foundation + протокол и модели проекта.

@MainActor
final class MockTaskRepository: TaskRepositoryProtocol {
    /// Текущее «хранилище». Тесты могут предзаполнять напрямую.
    var storedTasks: [Task] = []
    /// Если true — любой вызов бросает mockError (тест Alert/ошибок).
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
        // Mock хранит те же ссылки — объект уже мутирован вызывающим кодом.
        // Проверяем, что задача известна хранилищу (защита от некорректных вызовов).
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
