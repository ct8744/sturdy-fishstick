import Foundation

/// 导出用例
class ExportUseCase {
    private let exportService: ExportService
    private let billRepository: BillRepository

    init(exportService: ExportService, billRepository: BillRepository) {
        self.exportService = exportService
        self.billRepository = billRepository
    }

    /// 导出所有账单
    func exportAll() async throws -> URL {
        let records = try await billRepository.fetchAll()
        return try await exportService.exportToCSV(records: records)
    }

    /// 导出指定月份账单
    func exportMonth(year: Int, month: Int) async throws -> URL {
        let records = try await billRepository.fetchByMonth(year: year, month: month)
        return try await exportService.exportToCSV(records: records)
    }
}
