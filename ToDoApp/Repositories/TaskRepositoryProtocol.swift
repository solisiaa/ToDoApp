import Foundation

// MARK: - TaskFilter
// Фильтр списка. Живёт рядом с протоколом, т.к. используется
// в сигнатуре fetch — и ViewModel, и Repository, и тесты видят один тип.
// Зависимости: только Foundation.

enum TaskFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Все"
    case active = "Активные"
    case completed = "Выполненные"

    var id: String { rawValue }
}

// MARK: - TaskRepositoryProtocol
// Абстракция персистентности. ViewModel зависит ТОЛЬКО от неё —
// это позволяет подменять SwiftData на Mock в тестах без изменений ViewModel.
// Методы синхронные throws: ModelContext SwiftData — main-actor API,
// асинхронность здесь не даёт выигрыша (KISS). Ошибки пробрасываются
// наверх, ViewModel публикует их в errorMessage.

protocol TaskRepositoryProtocol: Sendable {
    /// Все задачи, новые сверху (createdAt DESC), с учётом фильтра.
    func fetch(filter: TaskFilter) throws -> [Task]
    /// Создаёт и сохраняет задачу. Пустой title — ошибка валидации.
    @discardableResult
    func create(
        title: String,
        details: String,
        dueDate: Date?,
        priority: Priority,
        category: Category?
    ) throws -> Task
    /// Обновляет поля уже отслеживаемой контекстом задачи.
    func update(_ task: Task) throws
    /// Инвертирует isCompleted (свайп-экшен).
    func toggleCompletion(_ task: Task) throws
    /// Удаляет задачу из хранилища.
    func delete(_ task: Task) throws
}

// MARK: - RepositoryError
// Доменовые ошибки слоя данных: валидация + обёртка над ошибками SwiftData.

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
