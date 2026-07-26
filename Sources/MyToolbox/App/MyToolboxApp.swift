import SwiftUI
import SwiftData

@main
struct MyToolboxApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // 配置 SwiftData 存储
            let schema = Schema([
                BillRecord.self,
                MainCategory.self,
                SubCategory.self,
                KeywordMap.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法初始化数据存储：\(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .modelContainer(modelContainer)
                .onAppear {
                    seedDefaultData()
                }
        }
    }

    /// 首次启动时写入默认分类和关键词
    private func seedDefaultData() {
        let context = modelContainer.mainContext
        let seeder = DefaultDataSeeder(modelContext: context)
        try? seeder.seedIfNeeded()
    }
}
