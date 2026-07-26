import Foundation

/// 月度统计用例
class MonthlySummaryUseCase {
    private let billRepository: BillRepository

    init(billRepository: BillRepository) {
        self.billRepository = billRepository
    }

    /// 计算指定月份的汇总数据
    func calculate(year: Int, month: Int) async throws -> MonthlySummary {
        let records = try await billRepository.fetchByMonth(year: year, month: month)

        let totalIncome = records
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let totalExpense = records
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let balance = totalIncome - totalExpense

        // 按大类计算支出分类明细
        let expenseRecords = records.filter { $0.type == .expense && $0.mainCategoryID != nil }
        let grouped = Dictionary(grouping: expenseRecords) { $0.mainCategoryID! }

        // 需要从外部获取分类名称，这里先用 ID 暂存
        var breakdowns: [CategoryBreakdown] = []
        for (catID, catRecords) in grouped {
            let total = catRecords.reduce(Decimal.zero) { $0 + $1.amount }
            let percentage = totalExpense > 0
                ? Double(truncating: (total * 100 / totalExpense) as NSDecimalNumber)
                : 0.0
            breakdowns.append(CategoryBreakdown(
                categoryID: catID,
                totalAmount: total,
                percentage: percentage
            ))
        }
        breakdowns.sort { $0.totalAmount > $1.totalAmount }

        // 日均支出
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: Calendar.current.date(from: DateComponents(year: year, month: month))!)?.count ?? 30
        let dailyAverage = daysInMonth > 0 ? totalExpense / Decimal(daysInMonth) : .zero

        return MonthlySummary(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            balance: balance,
            categoryBreakdowns: breakdowns,
            dailyAverage: dailyAverage
        )
    }

    /// 分类排行
    func categoryRanking(records: [BillRecord], level: RankingLevel) async throws -> [CategoryRankingItem] {
        let expenseRecords = records.filter { $0.type == .expense }
        let totalExpense = expenseRecords.reduce(Decimal.zero) { $0 + $1.amount }

        var grouped: [UUID: [BillRecord]]

        switch level {
        case .main:
            grouped = Dictionary(grouping: expenseRecords.filter { $0.mainCategoryID != nil }) { $0.mainCategoryID! }
        case .sub:
            grouped = Dictionary(grouping: expenseRecords.filter { $0.subCategoryID != nil }) { $0.subCategoryID! }
        }

        var items: [CategoryRankingItem] = []
        for (catID, catRecords) in grouped {
            let total = catRecords.reduce(Decimal.zero) { $0 + $1.amount }
            let percentage = totalExpense > 0
                ? Double(truncating: (total * 100 / totalExpense) as NSDecimalNumber)
                : 0.0
            items.append(CategoryRankingItem(
                categoryID: catID,
                categoryName: "",
                totalAmount: total,
                percentage: percentage,
                recordCount: catRecords.count
            ))
        }

        items.sort { $0.totalAmount > $1.totalAmount }
        return items
    }
}

// MARK: - 数据结构

struct MonthlySummary {
    let totalIncome: Decimal
    let totalExpense: Decimal
    let balance: Decimal
    var categoryBreakdowns: [CategoryBreakdown]
    let dailyAverage: Decimal
}

struct CategoryBreakdown {
    let categoryID: UUID
    let totalAmount: Decimal
    let percentage: Double
}

struct CategoryRankingItem {
    let categoryID: UUID
    var categoryName: String
    let totalAmount: Decimal
    let percentage: Double
    let recordCount: Int
}

enum RankingLevel {
    case main   // 大类排行
    case sub    // 小类排行
}
