import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class BillListViewModel {
    var records: [BillRecord] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // 筛选
    var selectedTypeFilter: TransactionType? = nil
    var selectedMonth: Date = Date()
    var searchText: String = ""

    // 分类名称缓存
    var mainCategoryNames: [UUID: String] = [:]
    var subCategoryNames: [UUID: String] = [:]

    private let billRepository: BillRepository
    private let categoryRepo: CategoryRepository

    init(billRepository: BillRepository, categoryRepo: CategoryRepository) {
        self.billRepository = billRepository
        self.categoryRepo = categoryRepo
    }

    func onAppear() async {
        await loadCategoryNames()
        await loadRecords()
    }

    func switchToMonth(_ date: Date) {
        selectedMonth = date
        Task { await loadRecords() }
    }

    func toggleTypeFilter(_ type: TransactionType?) {
        selectedTypeFilter = selectedTypeFilter == type ? nil : type
        Task { await loadRecords() }
    }

    func deleteRecord(_ record: BillRecord) {
        Task {
            try await billRepository.delete(record)
            await loadRecords()
        }
    }

    // MARK: - Private

    private func loadRecords() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)

        do {
            var allRecords = try await billRepository.fetchByMonth(year: year, month: month)

            // 类型筛选
            if let filter = selectedTypeFilter {
                allRecords = allRecords.filter { $0.type == filter }
            }

            // 搜索
            if !searchText.isEmpty {
                allRecords = allRecords.filter {
                    $0.merchantName.localizedCaseInsensitiveContains(searchText) ||
                    $0.tag.localizedCaseInsensitiveContains(searchText)
                }
            }

            records = allRecords
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadCategoryNames() async {
        if let mains = try? await categoryRepo.fetchMainCategories() {
            mainCategoryNames = Dictionary(uniqueKeysWithValues: mains.map { ($0.id, $0.name) })
        }
        if let subs = try? await categoryRepo.fetchAllSubCategories() {
            subCategoryNames = Dictionary(uniqueKeysWithValues: subs.map { ($0.id, $0.name) })
        }
    }
}
