import Foundation

/// 分类管理用例
class ManageCategoryUseCase {
    private let categoryRepo: CategoryRepository
    private let keywordRepo: KeywordMapRepository

    init(categoryRepo: CategoryRepository, keywordRepo: KeywordMapRepository) {
        self.categoryRepo = categoryRepo
        self.keywordRepo = keywordRepo
    }

    // MARK: - 大类 CRUD

    func createMainCategory(name: String) async throws -> MainCategory {
        let categories = try await categoryRepo.fetchMainCategories()
        let maxOrder = categories.map(\.sortOrder).max() ?? -1
        let category = MainCategory(name: name, sortOrder: maxOrder + 1)
        try await categoryRepo.addMainCategory(category)
        return category
    }

    func renameMainCategory(id: UUID, newName: String) async throws {
        guard let category = try await categoryRepo.fetchMainCategories().first(where: { $0.id == id }) else {
            throw DomainError.categoryNotFound
        }
        category.name = newName
        try await categoryRepo.updateMainCategory(category)
    }

    func deleteMainCategory(id: UUID) async throws {
        guard let category = try await categoryRepo.fetchMainCategories().first(where: { $0.id == id }) else {
            throw DomainError.categoryNotFound
        }
        // 删除大类时同步删除其下所有小类及关联的关键词映射
        let subCategories = try await categoryRepo.fetchSubCategories(for: id)
        for sub in subCategories {
            try await keywordRepo.deleteAll(for: sub.id)
        }
        try await categoryRepo.deleteMainCategory(category)
    }

    func reorderMainCategories(orderedIDs: [UUID]) async throws {
        for (index, id) in orderedIDs.enumerated() {
            guard let category = try await categoryRepo.fetchMainCategories().first(where: { $0.id == id }) else {
                continue
            }
            category.sortOrder = index
            try await categoryRepo.updateMainCategory(category)
        }
    }

    // MARK: - 小类 CRUD

    func createSubCategory(name: String, mainCategoryID: UUID) async throws -> SubCategory {
        let subs = try await categoryRepo.fetchSubCategories(for: mainCategoryID)
        let maxOrder = subs.map(\.sortOrder).max() ?? -1
        let sub = SubCategory(name: name, mainCategoryID: mainCategoryID, sortOrder: maxOrder + 1)
        try await categoryRepo.addSubCategory(sub)
        return sub
    }

    func renameSubCategory(id: UUID, newName: String) async throws {
        let subs = try await categoryRepo.fetchAllSubCategories()
        guard let sub = subs.first(where: { $0.id == id }) else {
            throw DomainError.subCategoryNotFound
        }
        sub.name = newName
        try await categoryRepo.updateSubCategory(sub)
    }

    func deleteSubCategory(id: UUID) async throws {
        let subs = try await categoryRepo.fetchAllSubCategories()
        guard let sub = subs.first(where: { $0.id == id }) else {
            throw DomainError.subCategoryNotFound
        }
        // 删除关联的关键词映射
        try await keywordRepo.deleteAll(for: id)
        try await categoryRepo.deleteSubCategory(sub)
    }

    func moveSubCategory(id: UUID, toMainCategoryID: UUID) async throws {
        let subs = try await categoryRepo.fetchAllSubCategories()
        guard let sub = subs.first(where: { $0.id == id }) else {
            throw DomainError.subCategoryNotFound
        }
        sub.mainCategoryID = toMainCategoryID
        try await categoryRepo.updateSubCategory(sub)
    }

    func reorderSubCategories(mainCategoryID: UUID, orderedIDs: [UUID]) async throws {
        for (index, id) in orderedIDs.enumerated() {
            let subs = try await categoryRepo.fetchSubCategories(for: mainCategoryID)
            guard let sub = subs.first(where: { $0.id == id }) else {
                continue
            }
            sub.sortOrder = index
            try await categoryRepo.updateSubCategory(sub)
        }
    }
}

enum DomainError: LocalizedError {
    case categoryNotFound
    case subCategoryNotFound

    var errorDescription: String? {
        switch self {
        case .categoryNotFound:    return "未找到该分类"
        case .subCategoryNotFound: return "未找到该子分类"
        }
    }
}
