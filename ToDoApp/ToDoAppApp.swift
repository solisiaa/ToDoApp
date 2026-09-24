import SwiftUI
import SwiftData

// MARK: - ToDoAppApp

@main
struct ToDoAppApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Task.self, Category.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
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
// Собирает Context → Repository → ViewModel. Отдельный View, т.к.
// @Environment недоступен напрямую в App.

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
                        let repository = TaskRepository(context: modelContext)
                        viewModel = TaskListViewModel(repository: repository)
                    }
            }
        }
    }
}
