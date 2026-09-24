import Testing
import Foundation
@testable import ToDoApp

// MARK: - TaskListViewModelTests
// Подключение: File → New → Target → Unit Testing Bundle, имя ToDoAppTests.

struct TaskListViewModelTests {
    // MARK: Helpers

    @MainActor
    private func makeSUT() -> (TaskListViewModel, MockTaskRepository) {
        let done = Task(title: "Готовая", isCompleted: true)
        let active1 = Task(title: "Активная 1", priority: .high)
        let active2 = Task(title: "Активная 2", priority: .low)
        let mock = MockTaskRepository(tasks: [done, active1, active2])
        let sut = TaskListViewModel(repository: mock)
        return (sut, mock)
    }

    // MARK: READ

    @Test("reload загружает все задачи при фильтре .all")
    @MainActor
    func reloadLoadsAllTasks() {
        let (sut, _) = makeSUT()
        sut.reload()
        #expect(sut.tasks.count == 3)
    }

    @Test("Фильтр .active скрывает выполненные")
    @MainActor
    func filterActiveHidesCompleted() {
        let (sut, _) = makeSUT()
        sut.filter = .active
        #expect(sut.tasks.count == 2)
        #expect(sut.tasks.allSatisfy { !$0.isCompleted })
    }

    @Test("Фильтр .completed показывает только выполненные")
    @MainActor
    func filterCompletedShowsOnlyDone() {
        let (sut, _) = makeSUT()
        sut.filter = .completed
        #expect(sut.tasks.count == 1)
        #expect(sut.tasks.allSatisfy(\.isCompleted))
    }

    @Test("Новые задачи идут первыми (createdAt DESC)")
    @MainActor
    func tasksSortedNewestFirst() {
        let (sut, _) = makeSUT()
        sut.reload()
        let dates = sut.tasks.map(\.createdAt)
        #expect(dates == dates.sorted(by: >))
    }

    // MARK: CREATE

    @Test("addTask добавляет задачу и закрывает sheet")
    @MainActor
    func addTaskAppendsAndClosesSheet() {
        let (sut, _) = makeSUT()
        sut.isShowingAddSheet = true
        sut.addTask(title: "Новая", details: "Детали", dueDate: nil, priority: .medium)
        #expect(sut.tasks.count == 4)
        #expect(sut.tasks.contains { $0.title == "Новая" })
        #expect(sut.isShowingAddSheet == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("addTask с пустым title показывает ошибку и не добавляет")
    @MainActor
    func addTaskWithEmptyTitleShowsError() {
        let (sut, _) = makeSUT()
        sut.addTask(title: "   ", details: "", dueDate: nil, priority: .medium)
        #expect(sut.tasks.count == 3)
        #expect(sut.errorMessage != nil)
    }

    // MARK: UPDATE

    @Test("toggle инвертирует isCompleted")
    @MainActor
    func toggleFlipsCompletion() {
        let (sut, _) = makeSUT()
        sut.reload()
        let task = sut.tasks.first { !$0.isCompleted }!
        sut.toggle(task)
        #expect(task.isCompleted == true)
    }

    @Test("applyEdit обновляет поля задачи")
    @MainActor
    func applyEditUpdatesFields() {
        let (sut, _) = makeSUT()
        sut.reload()
        let task = sut.tasks[0]
        sut.applyEdit(
            to: task,
            title: "Обновлённая",
            details: "Новый текст",
            dueDate: nil,
            priority: .high
        )
        #expect(task.title == "Обновлённая")
        #expect(task.details == "Новый текст")
        #expect(task.priority == .high)
        #expect(sut.taskToEdit == nil)
    }

    // MARK: DELETE

    @Test("delete удаляет задачу из списка")
    @MainActor
    func deleteRemovesTask() {
        let (sut, _) = makeSUT()
        sut.reload()
        let task = sut.tasks[0]
        sut.delete(task)
        #expect(sut.tasks.count == 2)
        #expect(!sut.tasks.contains { $0.id == task.id })
    }

    @Test("delete(at:) удаляет по IndexSet (swipe-to-delete)")
    @MainActor
    func deleteAtOffsetsRemovesTask() {
        let (sut, _) = makeSUT()
        sut.reload()
        sut.delete(at: IndexSet(integer: 0))
        #expect(sut.tasks.count == 2)
    }

    // MARK: ERRORS

    @Test("Ошибка репозитория публикуется в errorMessage")
    @MainActor
    func repositoryFailureSurfacesErrorMessage() {
        let (sut, mock) = makeSUT()
        mock.shouldFail = true
        sut.reload()
        #expect(sut.errorMessage != nil)
    }

    @Test("dismissError очищает ошибку")
    @MainActor
    func dismissErrorClearsMessage() {
        let (sut, mock) = makeSUT()
        mock.shouldFail = true
        sut.reload()
        #expect(sut.errorMessage != nil)
        sut.dismissError()
        #expect(sut.errorMessage == nil)
    }

    // MARK: CALENDAR (фильтр по дню)

    @Test("selectDay оставляет только задачи с дедлайном в этот день")
    @MainActor
    func selectDayFiltersByDueDate() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let mock = MockTaskRepository(tasks: [
            Task(title: "Сегодня", dueDate: today),
            Task(title: "Завтра", dueDate: tomorrow),
            Task(title: "Без срока", dueDate: nil),
        ])
        let sut = TaskListViewModel(repository: mock)
        sut.reload()
        #expect(sut.tasks.count == 3)
        sut.selectDay(today)
        #expect(sut.tasks.count == 1)
        #expect(sut.tasks.first?.title == "Сегодня")
    }

    @Test("Повторный тап по дню снимает фильтр")
    @MainActor
    func reselectingDayClearsFilter() {
        let (sut, _) = makeSUT()
        sut.reload()
        sut.selectDay(Date())
        let filtered = sut.tasks.count
        sut.selectDay(Date())
        #expect(sut.selectedDay == nil)
        #expect(sut.tasks.count == 3)
        #expect(sut.tasks.count >= filtered)
    }

    @Test("clearDayFilter возвращает полный список")
    @MainActor
    func clearDayFilterRestoresAll() {
        let mock = MockTaskRepository(tasks: [Task(title: "С дедлайном", dueDate: Date())])
        let sut = TaskListViewModel(repository: mock)
        sut.reload()
        sut.selectDay(Date().addingTimeInterval(86400 * 30))
        #expect(sut.tasks.isEmpty)
        sut.clearDayFilter()
        #expect(sut.tasks.count == 1)
    }

    @Test("daysWithTasks содержит дни дедлайнов без дублей")
    @MainActor
    func daysWithTasksListsUniqueDays() {
        let today = Date()
        let mock = MockTaskRepository(tasks: [
            Task(title: "A", dueDate: today),
            Task(title: "B", dueDate: today),
            Task(title: "C", dueDate: nil),
        ])
        let sut = TaskListViewModel(repository: mock)
        sut.reload()
        #expect(sut.daysWithTasks.count == 1)
    }
}
