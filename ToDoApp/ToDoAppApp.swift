import SwiftUI
import SwiftData

// MARK: - ToDoAppApp
// Точка входа. Здесь и только здесь создаётся ModelContainer —
// дальше ModelContext раздаётся через @Environment (\.modelContext).
// View забирает контекст и инжектит его в TaskRepository, из которого
// собирается TaskListViewModel. ViewModel о контейнере ничего не знает.
// Зависимости: SwiftUI, SwiftData, все слои приложения.

@main
struct ToDoAppApp: App {
    /// Контейнер SwiftData для Task и Category. CloudKit выключен по умолчанию
    /// (включается опцией cloudKitDatabase при необходимости синхронизации).
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Task.self, Category.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Падение на старте осознанное: без хранилища приложение
            // неработоспособно, лучше упасть громко, чем молча терять данные.
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(container)
    }
}

// MARK: - AppRootView
// Мостик между SwiftData-слоем и MVVM: забирает ModelContext из @Environment,
// собирает Repository → ViewModel и отдаёт в TaskListView.
// Выделен в отдельный View, т.к. @Environment доступен только внутри иерархии
// под .modelContainer — напрямую в App его прочитать нельзя.
// Хранит ViewModel в @State (iOS 17-паттерн для @Observable), переживает перерисовки.

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TaskListViewModel?

    var body: some View {
        Group {
            if let viewModel {
                TaskListView(viewModel: viewModel)
            } else {
                ProgressView("Загрузка…")
                    .onAppear {
                        // Сборка графа зависимостей: Context → Repository → ViewModel.
                        let repository = TaskRepository(context: modelContext)
                        viewModel = TaskListViewModel(repository: repository)
                    }
            }
        }
    }
}
