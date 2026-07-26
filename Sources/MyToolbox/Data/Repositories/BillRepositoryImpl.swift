import Foundation
import SwiftData
import Combine

@MainActor
class BillRepositoryImpl: BillRepository {
    private let modelContext: ModelContext
    private let changeSubject = PassthroughSubject<Void, Never>()

    var didChange: AnyPublisher<Void, Never> {
        changeSubject.eraseToAnyPublisher()
    }

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
        changeSubject.send()
    }

    func addBatch(_ records: [BillRecord]) async throws {
        for record in records {
            modelContext.insert(record)
        }
        try modelContext.save()
        changeSubject.send()
    }

    func update(_ record: BillRecord) async throws {
        try modelContext.save()
        changeSubject.send()
    }

    func delete(_ record: BillRecord) async throws {
        modelContext.delete(record)
        try modelContext.save()
        changeSubject.send()
    }

    func deleteBatch(_ records: [BillRecord]) async throws {
        for record in records {
            modelContext.delete(record)
        }
        try modelContext.save()
        changeSubject.send()
    }
}
