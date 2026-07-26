import Foundation
import SwiftUI
import Observation
import Combine

@MainActor
@Observable
class HomeViewModel {
    // 状态
    var selectedMonth: Date = Date()
    var summary: MonthlySummary?
    var rankingLevel: RankingLevel = .main
    var rankingItems: [CategoryRankingItem] = []
    var recentRecords: [BillRecord] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // 分类名称缓存
    var mainCategoryNames: [UUID: String] = [:]
    var subCategoryNames: [UUID: String] = [:]

    private let summaryUseCase: MonthlySummaryUseCase
    private let billRepository: BillRepository
    private let categoryRepo: CategoryRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        summaryUseCase: MonthlySummaryUseCase,
        billRepository: BillRepository,
        categoryRepo: CategoryRepository
    ) {
        self.summaryUseCase = summaryUseCase
        self.billRepository = billRepository
        self.categoryRepo = categoryRepo

        // 订阅数据变更，自动刷新
        billRepository.didChange
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.loadMonthData() }
            }
            .store(in: &cancellables)
    }

    func onAppear() async {
        await loadCategoryNames()
        await loadMonthData()
    }

    func switchToMonth(_ date: Date) {
        selectedMonth = date
        Task { await loadMonthData() }
    }

    func toggleRankingLevel() {
        rankingLevel = rankingLevel == .main ? .sub : .main
        Task { await loadRanking() }
    }

    // MARK: - Private

    private func loadMonthData() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)

        guard let year = components.year, let month = components.month else { return }

        do {
            summary = try await summaryUseCase.calculate(year: year, month: month)

            await loadRanking()
            await loadRecentRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRanking() async {
        guard let records = try? await billRepository.fetchByMonth(
            year: Calendar.current.component(.year, from: selectedMonth),
            month: Calendar.current.component(.month, from: selectedMonth)
        ) else { return }

        rankingItems = (try? await summaryUseCase.categoryRanking(records: records, level: rankingLevel)) ?? []

        // 填充分类名称
        for i in 0..<rankingItems.count {
            let name: String
            switch rankingLevel {
            case .main:
                name = mainCategoryNames[rankingItems[i].categoryID] ?? "未分类"
            case .sub:
                name = subCategoryNames[rankingItems[i].categoryID] ?? "未分类"
            }
            rankingItems[i].categoryName = name
        }
    }

    private func loadRecentRecords() async {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
        recentRecords = (try? await billRepository.fetchByDateRange(start: start, end: end)) ?? []
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
