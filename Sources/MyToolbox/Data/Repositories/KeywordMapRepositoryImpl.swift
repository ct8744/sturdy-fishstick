import Foundation
import SwiftData

@MainActor
class KeywordMapRepositoryImpl: KeywordMapRepository {
    private let modelContext: ModelContext
    // 缓存所有关键词映射，减少重复查询
    private var cachedMaps: [KeywordMap] = []
    private var cacheLoaded = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [KeywordMap] {
        let descriptor = FetchDescriptor<KeywordMap>(sortBy: [SortDescriptor(\.priority, order: .reverse)])
        let maps = try modelContext.fetch(descriptor)
        cachedMaps = maps
        cacheLoaded = true
        return maps
    }

    func match(merchantName: String) async throws -> (mainCategoryID: UUID, subCategoryID: UUID)? {
        if !cacheLoaded {
            _ = try await fetchAll()
        }

        // 按 priority 降序匹配，优先匹配最长关键词
        let sorted = cachedMaps.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority > rhs.priority
            }
            return lhs.keyword.count > rhs.keyword.count
        }

        // 找到第一个匹配的关键词
        guard let matched = sorted.first(where: { merchantName.contains($0.keyword) }) else {
            return nil
        }

        // 通过 subCategoryID 查找关联的大类 ID
        let subDescriptor = FetchDescriptor<SubCategory>(
            predicate: #Predicate { $0.id == matched.subCategoryID }
        )
        guard let subCategory = try modelContext.fetch(subDescriptor).first else {
            return nil
        }

        return (subCategory.mainCategoryID, matched.subCategoryID)
    }

    func add(_ map: KeywordMap) async throws {
        modelContext.insert(map)
        try modelContext.save()
        cachedMaps.append(map)
    }

    func update(_ map: KeywordMap) async throws {
        try modelContext.save()
        // 刷新缓存
        if let index = cachedMaps.firstIndex(where: { $0.id == map.id }) {
            cachedMaps[index] = map
        }
    }

    func delete(_ map: KeywordMap) async throws {
        modelContext.delete(map)
        try modelContext.save()
        cachedMaps.removeAll { $0.id == map.id }
    }

    /// 删除指定小类关联的所有关键词映射
    func deleteAll(for subCategoryID: UUID) async throws {
        if !cacheLoaded {
            _ = try await fetchAll()
        }
        let toDelete = cachedMaps.filter { $0.subCategoryID == subCategoryID }
        for map in toDelete {
            modelContext.delete(map)
        }
        try modelContext.save()
        cachedMaps.removeAll { $0.subCategoryID == subCategoryID }
    }
}
