import Foundation
import SwiftData

@MainActor
class BillRepositoryImpl: BillRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [BillRecord] {
        let descriptor = FetchDescriptor<BillRecord>(sortBy: [SortDescriptor(\.transactionTime, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func fetchByID(_ id: UUID) async throws -> BillRecord? {
        let all = try await fetchAll()
        return all.first { $0.id == id }
    }

    func fetchByMonth(year: Int, month: Int) async throws -> [BillRecord] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        let all = try await fetchAll()
        return all.filter { $0.transactionTime >= startDate && $0.transactionTime < endDate }
    }

    func fetchByDateRange(start: Date, end: Date) async throws -> [BillRecord] {
        let all = try await fetchAll()
        return all.filter { $0.transactionTime >= start && $0.transactionTime <= end }
    }

    func fetchByCategory(mainCategoryID: UUID) async throws -> [BillRecord] {
        let all = try await fetchAll()
        return all.filter { $0.mainCategoryID == mainCategoryID }
    }

    func fetchByCategory(subCategoryID: UUID) async throws -> [BillRecord] {
        let all = try await fetchAll()
        return all.filter { $0.subCategoryID == subCategoryID }
    }

    func add(_ record: BillRecord) async throws {
        modelContext.insert(record)
        try modelContext.save()
    }

    func addBatch(_ records: [BillRecord]) async throws {
        for record in records {
            modelContext.insert(record)
        }
        try modelContext.save()
    }

    func update(_ record: BillRecord) async throws {
        try modelContext.save()
    }

    func delete(_ record: BillRecord) async throws {
        modelContext.delete(record)
        try modelContext.save()
    }

    func deleteBatch(_ records: [BillRecord]) async throws {
        for record in records {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
