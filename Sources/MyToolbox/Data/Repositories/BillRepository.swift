import Foundation
import Combine

protocol BillRepository {
    var didChange: AnyPublisher<Void, Never> { get }

    func fetchAll() async throws -> [BillRecord]
    func fetchByID(_ id: UUID) async throws -> BillRecord?
    func fetchByMonth(year: Int, month: Int) async throws -> [BillRecord]
    func fetchByDateRange(start: Date, end: Date) async throws -> [BillRecord]
    func fetchByCategory(mainCategoryID: UUID) async throws -> [BillRecord]
    func fetchByCategory(subCategoryID: UUID) async throws -> [BillRecord]

    func add(_ record: BillRecord) async throws
    func addBatch(_ records: [BillRecord]) async throws
    func update(_ record: BillRecord) async throws
    func delete(_ record: BillRecord) async throws
    func deleteBatch(_ records: [BillRecord]) async throws
}
