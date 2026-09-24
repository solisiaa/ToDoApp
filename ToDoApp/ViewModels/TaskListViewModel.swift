import Foundation
import Observation

// MARK: - TaskListViewModel

@Observable
@MainActor
final class TaskListViewModel {
    // MARK: State

    private(set) var tasks: [Task] = []
    var filter: TaskFilter = .all {
        didSet { reload() }
    }
    var selectedDay: Date? {
        didSet { applyFilters() }
    }
    var isCalendarVisible = false
    var errorMessage: String?
    var isShowingAddSheet = false
    var taskToEdit: Task?

    // MARK: Dependencies

    private let repository: TaskRepositoryProtocol
    private var fetchedTasks: [Task] = []
    private let calendar = Calendar.current

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: Intentions

    func reload() {
        do {
            fetchedTasks = try repository.fetch(filter: filter)
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Календарь

    private func applyFilters() {
        guard let day = selectedDay else {
            tasks = fetchedTasks
            return
        }
        tasks = fetchedTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: day)
        }
    }

    func selectDay(_ date: Date) {
        if let current = selectedDay, calendar.isDate(current, inSameDayAs: date) {
            selectedDay = nil
        } else {
            selectedDay = calendar.startOfDay(for: date)
        }
    }

    func clearDayFilter() {
        selectedDay = nil
    }

    var selectedDayTitle: String {
        guard let day = selectedDay else { return "" }
        return day.formatted(.dateTime.day().month(.wide).year())
    }

    var daysWithTasks: [Date] {
        let days = fetchedTasks.compactMap(\.dueDate).map { calendar.startOfDay(for: $0) }
        return Array(Set(days)).sorted()
    }

    func addTask(
        title: String,
        details: String,
        dueDate: Date?,
        priority: Priority
    ) {
        do {
            try repository.create(
                title: title,
                details: details,
                dueDate: dueDate,
                priority: priority,
                category: nil
            )
            isShowingAddSheet = false
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyEdit(
        to task: Task,
        title: String,
        details: String,
        dueDate: Date?,
        priority: Priority
    ) {
        do {
            task.title = title
            task.details = details
            task.dueDate = dueDate
            task.priority = priority
            try repository.update(task)
            taskToEdit = nil
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ task: Task) {
        do {
            try repository.toggleCompletion(task)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ task: Task) {
        do {
            try repository.delete(task)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            delete(tasks[index])
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
