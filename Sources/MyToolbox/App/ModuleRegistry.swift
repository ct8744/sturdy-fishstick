import Foundation
import SwiftData

/// 模块注册中心 — 管理各层的依赖关系
/// 遵循 Clean Architecture 依赖规则：UI → ViewModel → Domain → Data
@MainActor
final class ModuleRegistry {
    let modelContext: ModelContext

    // MARK: - Data 层

    private(set) lazy var billRepository: BillRepository = BillRepositoryImpl(modelContext: modelContext)
    private(set) lazy var categoryRepository: CategoryRepository = CategoryRepositoryImpl(modelContext: modelContext)
    private(set) lazy var keywordMapRepository: KeywordMapRepository = KeywordMapRepositoryImpl(modelContext: modelContext)
    private(set) lazy var exportService: ExportService = CSVExportService()

    // MARK: - Domain 层

    private(set) lazy var monthlySummaryUseCase = MonthlySummaryUseCase(billRepository: billRepository)
    private(set) lazy var manageCategoryUseCase = ManageCategoryUseCase(
        categoryRepo: categoryRepository,
        keywordRepo: keywordMapRepository
    )
    private(set) lazy var autoCategorizeUseCase = AutoCategorizeUseCase(keywordRepo: keywordMapRepository)
    private(set) lazy var exportUseCase = ExportUseCase(
        exportService: exportService,
        billRepository: billRepository
    )

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
