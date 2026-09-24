import Foundation
import SwiftData

// MARK: - TaskRepository
// Единственное место, знающее о SwiftData. ModelContext приходит извне
// (инжектится из View через @Environment), сам репозиторий контекст не создаёт.
// @MainActor: ModelContext привязан к main actor — все операции выполняем на нём.
// Решение: вся работа с FetchDescriptor/сортировкой инкапсулирована здесь,
// ViewModel получает готовый отсортированный массив и ничего не знает о SwiftData.

@MainActor
final class TaskRepository: TaskRepositoryProtocol {
    private let context: ModelContext

    /// - Parameter context: ModelContext из @Environment (см. ToDoAppApp).
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: READ

    func fetch(filter: TaskFilter) throws -> [Task] {
        // Сортировка: новые сверху. Предикат строится по фильтру.
        let sort = SortDescriptor<Task>(\.createdAt, order: .reverse)
        let descriptor: FetchDescriptor<Task>
        switch filter {
        case .all:
            descriptor = FetchDescriptor(sortBy: [sort])
        case .active:
            descriptor = FetchDescriptor(
                predicate: #Predicate { !$0.isCompleted },
                sortBy: [sort]
            )
        case .completed:
            descriptor = FetchDescriptor(
                predicate: #Predicate { $0.isCompleted },
                sortBy: [sort]
            )
        }
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RepositoryError.underlying(error)
        }
    }

    // MARK: CREATE

    @discardableResult
    func create(
        title: String,
        details: String = "",
        dueDate: Date? = nil,
        priority: Priority = .medium,
        category: Category? = nil
    ) throws -> Task {
        // Валидация на границе слоя данных — защищает от пустых записей
        // при любом вызывающем коде, не только из формы.
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RepositoryError.emptyTitle
        }
        let task = Task(
            title: trimmed,
            details: details,
            dueDate: dueDate,
            priority: priority,
            category: category
        )
        context.insert(task)
        try save()
        return task
    }

    // MARK: UPDATE

    /// Task уже отслеживается контекстом (объект из fetch), поэтому
    /// достаточно вызвать save — SwiftData подхватит изменённые поля.
    func update(_ task: Task) throws {
        let trimmed = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RepositoryError.emptyTitle
        }
        task.title = trimmed
        try save()
    }

    func toggleCompletion(_ task: Task) throws {
        task.isCompleted.toggle()
        try save()
    }

    // MARK: DELETE

    func delete(_ task: Task) throws {
        context.delete(task)
        try save()
    }

    // MARK: Private

    private func save() throws {
        do {
            try context.save()
        } catch {
            throw RepositoryError.underlying(error)
        }
    }
}
