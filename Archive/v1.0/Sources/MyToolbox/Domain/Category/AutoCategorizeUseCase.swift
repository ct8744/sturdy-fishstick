import Foundation

/// 自动分类用例 — 根据关键词映射匹配商户名
class AutoCategorizeUseCase {
    private let keywordRepo: KeywordMapRepository

    init(keywordRepo: KeywordMapRepository) {
        self.keywordRepo = keywordRepo
    }

    /// 对单条记录尝试自动分类
    /// 返回匹配到的 (mainCategoryID, subCategoryID)，匹配失败返回 nil
    func categorize(record: BillRecord) async throws -> (UUID, UUID)? {
        guard !record.merchantName.isEmpty else { return nil }
        return try await keywordRepo.match(merchantName: record.merchantName)
    }

    /// 批量处理：分出已匹配和未匹配
    func batchCategorize(records: [BillRecord]) async throws -> (matched: [(BillRecord, UUID, UUID)], unmatched: [BillRecord]) {
        var matched: [(BillRecord, UUID, UUID)] = []
        var unmatched: [BillRecord] = []

        for record in records {
            if let (mainID, subID) = try await categorize(record: record) {
                matched.append((record, mainID, subID))
                record.mainCategoryID = mainID
                record.subCategoryID = subID
            } else {
                unmatched.append(record)
            }
        }

        return (matched, unmatched)
    }
}
