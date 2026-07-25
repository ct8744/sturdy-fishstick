import Foundation

protocol KeywordMapRepository {
    func fetchAll() async throws -> [KeywordMap]
    func match(merchantName: String) async throws -> (mainCategoryID: UUID, subCategoryID: UUID)?
    func add(_ map: KeywordMap) async throws
    func update(_ map: KeywordMap) async throws
    func delete(_ map: KeywordMap) async throws
    func deleteAll(for subCategoryID: UUID) async throws
    func deleteAll() async throws
}
