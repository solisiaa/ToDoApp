import SwiftUI

// MARK: - TaskListView
// Главный экран. Работает ТОЛЬКО с ViewModel: никакого @Query/@FetchRequest
// и прямого доступа к ModelContext — строго по архитектурному правилу №1, 2.
// NavigationStack + Segmented Picker + ContentUnavailableView + свайп-экшены
// (toggle, delete) + sheet-модалки Add/Edit + Alert ошибок из errorMessage.
// Зависимости: SwiftUI, ViewModels (TaskListViewModel), Models (TaskFilter).

struct TaskListView: View {
    @Bindable var viewModel: TaskListViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Фильтрация Все / Активные / Выполненные.
                Picker("Фильтр", selection: $viewModel.filter) {
                    ForEach(TaskFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Раскрывающаяся панель-календарь: месяц + выбор дня.
                if viewModel.isCalendarVisible {
                    CalendarPanelView(viewModel: viewModel)
                        .padding(.horizontal)
                }

                if viewModel.tasks.isEmpty {
                    // Пустое состояние вместо голого List.
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: emptyIcon)
                    } description: {
                        Text(emptyDescription)
                    } actions: {
                        Button("Добавить задачу") {
                            viewModel.isShowingAddSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(viewModel.tasks) { task in
                            TaskRowView(
                                task: task,
                                onToggle: { viewModel.toggle(task) },
                                onEdit: { viewModel.taskToEdit = task }
                            )
                            // Свайп влево: выполнить + удалить.
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.delete(task)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                                Button {
                                    viewModel.toggle(task)
                                } label: {
                                    Label(
                                        task.isCompleted ? "Вернуть" : "Готово",
                                        systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                    )
                                }
                                .tint(task.isCompleted ? .orange : .green)
                            }
                            // Свайп вправо: редактировать.
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.taskToEdit = task
                                } label: {
                                    Label("Изменить", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete { viewModel.delete(at: $0) }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Задачи")
            .toolbar {
                // Кнопка календаря: открывает/закрывает панель месяца.
                // Залита синим, пока активен фильтр по дню.
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.isCalendarVisible.toggle()
                    } label: {
                        Label("Календарь", systemImage: "calendar")
                    }
                    .tint(viewModel.selectedDay != nil ? .blue : nil)
                    .symbolVariant(viewModel.selectedDay != nil ? .fill : .none)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Label("Добавить задачу", systemImage: "plus")
                    }
                }
            }
            // CREATE: sheet добавления.
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddTaskView(viewModel: viewModel)
            }
            // UPDATE: sheet редактирования (item-based — закрытие сбрасывает taskToEdit в nil).
            .sheet(item: $viewModel.taskToEdit) { task in
                EditTaskView(viewModel: viewModel, task: task)
            }
            // Ошибки сохранения из ViewModel.
            .alert("Ошибка", isPresented: errorPresented) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "Неизвестная ошибка")
            }
            .onAppear {
                viewModel.reload()
            }
        }
    }

    // MARK: Empty state

    /// Binding для Alert: показан, пока errorMessage != nil.
    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }

    private var emptyTitle: String {
        // Day-фильтр приоритетнее: объясняем, что пусто именно в этот день.
        if viewModel.selectedDay != nil {
            viewModel.selectedDayTitle
        } else {
            switch viewModel.filter {
            case .all: "Нет задач"
            case .active: "Нет активных задач"
            case .completed: "Нет выполненных задач"
            }
        }
    }

    private var emptyIcon: String {
        if viewModel.selectedDay != nil {
            "calendar"
        } else {
            switch viewModel.filter {
            case .all: "tray"
            case .active: "circle"
            case .completed: "checkmark.circle"
            }
        }
    }

    private var emptyDescription: String {
        if viewModel.selectedDay != nil {
            "На этот день задач с дедлайном нет. Выберите другой день или сбросьте фильтр."
        } else {
            switch viewModel.filter {
            case .all: "Нажмите «Добавить задачу», чтобы создать первую."
            case .active: "Все задачи выполнены. Так держать!"
            case .completed: "Выполните задачу, и она появится здесь."
            }
        }
    }
}

#Preview {
    TaskListView(viewModel: TaskListViewModel(repository: MockTaskRepository()))
}
