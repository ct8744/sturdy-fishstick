import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let categoryID: UUID
    let categoryName: String
    private let modelContext: ModelContext

    @State private var records: [BillRecord] = []

    init(modelContext: ModelContext, categoryID: UUID, categoryName: String) {
        self.modelContext = modelContext
        self.categoryID = categoryID
        self.categoryName = categoryName
    }

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "暂无记录",
                    systemImage: "tray",
                    description: Text("该分类下暂无账单")
                )
            } else {
                List(records) { record in
                    BillRowView(
                        record: record,
                        mainCategoryName: categoryName,
                        subCategoryName: nil
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(categoryName)
        .task {
            let repo = BillRepositoryImpl(modelContext: modelContext)
            records = (try? await repo.fetchByCategory(mainCategoryID: categoryID)) ?? []
        }
    }
}
