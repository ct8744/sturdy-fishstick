import Foundation
import SwiftData

@MainActor
class CategoryRepositoryImpl: CategoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchMainCategories() async throws -> [MainCategory] {
        let descriptor = FetchDescriptor<MainCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    func fetchSubCategories(for mainCategoryID: UUID) async throws -> [SubCategory] {
        let descriptor = FetchDescriptor<SubCategory>(
            predicate: #Predicate { $0.mainCategoryID == mainCategoryID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllSubCategories() async throws -> [SubCategory] {
        let descriptor = FetchDescriptor<SubCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    func addMainCategory(_ category: MainCategory) async throws {
        modelContext.insert(category)
        try modelContext.save()
    }

    func updateMainCategory(_ category: MainCategory) async throws {
        try modelContext.save()
    }

    func deleteMainCategory(_ category: MainCategory) async throws {
        // 同步删除其下所有小类
        let subCategories = try await fetchSubCategories(for: category.id)
        for sub in subCategories {
            modelContext.delete(sub)
        }
        // 删除大类
        modelContext.delete(category)
        try modelContext.save()
    }

    func addSubCategory(_ category: SubCategory) async throws {
        modelContext.insert(category)
        try modelContext.save()
    }

    func updateSubCategory(_ category: SubCategory) async throws {
        try modelContext.save()
    }

    func deleteSubCategory(_ category: SubCategory) async throws {
        modelContext.delete(category)
        try modelContext.save()
    }
}
