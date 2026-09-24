import SwiftUI

// MARK: - CalendarPanelView
// Панель-календарь: помесячная сетка + выбор дня для фильтрации списка.
// Глупый View: всё состояние (selectedDay, дни с задачами) — во ViewModel,
// локально хранится только отображаемый месяц (чисто UI-состояние).
// Точки под числами = дни с дедлайнами (данные из viewModel.daysWithTasks).
// Повторный тап по выбранному дню снимает фильтр (логика в selectDay).
// Зависимости: SwiftUI, ViewModels (TaskListViewModel).

struct CalendarPanelView: View {
    @Bindable var viewModel: TaskListViewModel
    /// Какой месяц показан. По умолчанию — месяц выбранного дня или текущий.
    @State private var displayedMonth: Date

    private let calendar = Calendar.current

    init(viewModel: TaskListViewModel) {
        self.viewModel = viewModel
        let anchor = viewModel.selectedDay ?? Date()
        // Начало месяца якорной даты.
        let comps = Calendar.current.dateComponents([.year, .month], from: anchor)
        _displayedMonth = State(initialValue: Calendar.current.date(from: comps) ?? anchor)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Шапка: месяц + навигация + «Сегодня».
            HStack {
                Button {
                    displayedMonth = shiftedMonth(by: -1)
                } label: {
                    Label("Предыдущий месяц", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                Spacer()
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .textCase(nil)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Button("Сегодня") {
                    let today = Date()
                    displayedMonth = monthStart(of: today)
                    viewModel.selectDay(today)
                }
                .font(.subheadline)
                Button {
                    displayedMonth = shiftedMonth(by: 1)
                } label: {
                    Label("Следующий месяц", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }

            // Дни недели (короткие, с учётом firstWeekday локали).
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Сетка месяца: 7 колонок, ячейки с точками.
            // Итерация по индексам: пустых ячеек (nil) несколько,
            // и у них был бы одинаковый id — SwiftUI не допускает дублей.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(monthCells.indices, id: \.self) { index in
                    if let date = monthCells[index] {
                        DayCell(
                            date: date,
                            isSelected: isSelected(date),
                            hasTasks: daysWithTasksSet.contains(startOfDay(date)),
                            isToday: calendar.isDateInToday(date)
                        )
                        .onTapGesture { viewModel.selectDay(date) }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }

            // Подвал: статус фильтра + сброс.
            if viewModel.selectedDay != nil {
                HStack {
                    Text("Задачи на \(viewModel.selectedDayTitle): \(viewModel.tasks.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Сбросить") { viewModel.clearDayFilter() }
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Helpers

    /// Короткие символы дней недели, повёрнутые под firstWeekday (в RU — понедельник).
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1 // 0-based
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Ячейки месяца: nil = пустая клетка до 1-го числа.
    private var monthCells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDate = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        // Сдвиг первого дня с учётом firstWeekday.
        let leading = (calendar.component(.weekday, from: firstDate) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: firstDate))
        }
        return cells
    }

    private var daysWithTasksSet: Set<Date> {
        Set(viewModel.daysWithTasks)
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = viewModel.selectedDay else { return false }
        return calendar.isDate(selected, inSameDayAs: date)
    }

    private func shiftedMonth(by value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func monthStart(of date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

// MARK: - DayCell
// Одна клетка дня: число + синий круг если выбран + точка если есть задачи + жирное если сегодня.

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasTasks: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.blue : Color.clear, in: Circle())
            // Точка-маркер: видна всегда, если есть задачи (под синим кругом — белая).
            Circle()
                .fill(hasTasks ? (isSelected ? .white : .blue) : .clear)
                .frame(width: 4, height: 4)
        }
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    let mock = MockTaskRepository(tasks: [
        Task(title: "Сегодня", dueDate: Date(), priority: .high),
        Task(title: "Завтра", dueDate: Date().addingTimeInterval(86400)),
    ])
    CalendarPanelView(viewModel: TaskListViewModel(repository: mock))
}
