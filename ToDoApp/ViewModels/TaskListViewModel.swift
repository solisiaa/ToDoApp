import Foundation
import Observation

// MARK: - TaskListViewModel
// Единственный источник состояния для списка задач.
// @Observable (Observation framework) вместо ObservableObject/@Published:
// меньше бойлерплейта, трекинг на уровне свойств, нативная поддержка iOS 17.
// ViewModel зависит только от TaskRepositoryProtocol — SwiftData здесь
// не импортируется и не упоминается, что делает класс тестируемым с Mock.
// @MainActor: все мутации состояния UI обязаны происходить на main actor.
// Зависимости: Foundation, Observation, Models (Task), Repositories (протокол).

@Observable
@MainActor
final class TaskListViewModel {
    // MARK: State (читает View)

    /// Задачи, готовые к отображению (отсортированы репозиторием,
    /// затем отфильтрованы по выбранному дню — см. applyFilters).
    private(set) var tasks: [Task] = []
    /// Активный фильтр сегмент-контрола. didSet перезагружает список.
    var filter: TaskFilter = .all {
        didSet { reload() }
    }
    /// Выбранный в календаре день. nil = фильтр по дню выключен.
    /// didSet только переприменяет фильтры in-memory, без похода в хранилище.
    var selectedDay: Date? {
        didSet { applyFilters() }
    }
    /// Показывать ли панель-календарь (раскрывается кнопкой в тулбаре).
    var isCalendarVisible = false
    /// Текст ошибки для Alert. nil = алерта нет.
    var errorMessage: String?
    /// Флаги sheet-модалок — View биндится напрямую.
    var isShowingAddSheet = false
    var taskToEdit: Task?

    // MARK: Dependencies

    private let repository: TaskRepositoryProtocol
    /// Сырой результат последнего fetch (со статус-фильтром репозитория,
    /// но БЕЗ day-фильтра). Day-фильтр применяется поверх в applyFilters,
    /// чтобы переключение дней в календаре не дёргало хранилище.
    private var fetchedTasks: [Task] = []
    private let calendar = Calendar.current

    /// - Parameter repository: любая реализация протокола (SwiftData или Mock в тестах).
    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: Intentions (вызывает View)

    /// Первичная загрузка + перезагрузка после каждого изменения.
    /// Стратегия "перечитать из хранилища после мутации": список всегда
    /// консистентен с диском ценой одного fetch (для объёмов to-do — бесплатно).
    func reload() {
        do {
            fetchedTasks = try repository.fetch(filter: filter)
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Календарь (фильтр по дню)

    /// Накладывает day-фильтр на уже загруженные задачи.
    /// День сравнивается по календарным суткам (время игнорируется),
    /// совпадение идёт по dueDate — т.е. «что нужно сделать в этот день».
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

    /// Выбор дня в календаре. Повторный тап по тому же дню снимает фильтр.
    func selectDay(_ date: Date) {
        if let current = selectedDay, calendar.isDate(current, inSameDayAs: date) {
            selectedDay = nil
        } else {
            // Нормализуем к началу дня, чтобы сравнение было стабильным.
            selectedDay = calendar.startOfDay(for: date)
        }
    }

    /// Сброс day-фильтра (кнопка «Сбросить» под календарём).
    func clearDayFilter() {
        selectedDay = nil
    }

    /// Заголовок для панели календаря, напр. «12 октября 2026».
    var selectedDayTitle: String {
        guard let day = selectedDay else { return "" }
        return day.formatted(.dateTime.day().month(.wide).year())
    }

    /// Сколько задач с дедлайном приходится на каждый день текущего набора.
    /// Используется для точек-маркеров под календарём (первые 5 дней).
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

    /// Применяет отредактированные в форме поля к задаче и сохраняет.
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

    /// Swipe-to-delete передаёт IndexSet — маппим на уже отфильтрованный массив.
    func delete(at offsets: IndexSet) {
        for index in offsets {
            delete(tasks[index])
        }
    }

    /// Закрытие Alert по кнопке OK.
    func dismissError() {
        errorMessage = nil
    }
}
