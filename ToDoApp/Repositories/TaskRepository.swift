import Foundation
import SwiftData

// MARK: - TaskRepository

@MainActor
final class TaskRepository: TaskRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: READ

    func fetch(filter: TaskFilter) throws -> [Task] {
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
