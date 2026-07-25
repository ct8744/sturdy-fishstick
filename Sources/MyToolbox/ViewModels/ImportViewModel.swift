import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ImportViewModel {
    // 状态机 — 导入流程的各个阶段
    enum ImportStage {
        case selectSource       // 选择来源（微信/支付宝/自定义）
        case selectFile         // 选择文件
        case parsing            // 正在解析
        case mapping            // 展示映射结果 + 去重选项
        case autoCategorizing   // 自动分类中
        case manualCategorize   // 手动分类弹窗（需用户逐条确认）
        case completed          // 导入完成
        case failed(String)     // 导入失败
    }

    var stage: ImportStage = .selectSource
    var selectedFormat: FileFormat?
    var parsedRecords: [BillRecord] = []
    var matchedRecords: [(BillRecord, mainCategoryName: String, subCategoryName: String)] = []
    var unmatchedRecords: [BillRecord] = []
    var duplicateRecords: [BillRecord] = []
    var shouldDeduplicate: Bool = true   // 默认开启去重
    var currentUnmatchedIndex: Int = 0   // 当前手动分类到第几条
    var importProgress: Double = 0       // 进度 0~1

    // 手动分类时可用的大类/小类列表
    var availableMainCategories: [MainCategory] = []
    var availableSubCategories: [SubCategory] = []
    var selectedMainCategoryID: UUID?
    var selectedSubCategoryID: UUID?

    private let billRepository: BillRepository
    private let categoryRepo: CategoryRepository
    private let autoCategorizeUseCase: AutoCategorizeUseCase
    private var importOrchestrator: ImportOrchestrator?

    init(
        billRepository: BillRepository,
        categoryRepo: CategoryRepository,
        autoCategorizeUseCase: AutoCategorizeUseCase
    ) {
        self.billRepository = billRepository
        self.categoryRepo = categoryRepo
        self.autoCategorizeUseCase = autoCategorizeUseCase
    }

    func selectSource(_ format: FileFormat) {
        selectedFormat = format
        stage = .selectFile
    }

    func selectFile(url: URL) {
        stage = .parsing
        importProgress = 0.1
        Task { await startParsing(fileURL: url) }
    }

    func confirmDeduplicate(_ enable: Bool) {
        shouldDeduplicate = enable
    }

    func confirmCategory(mainCategoryID: UUID, subCategoryID: UUID) {
        guard currentUnmatchedIndex < unmatchedRecords.count else { return }
        let record = unmatchedRecords[currentUnmatchedIndex]
        record.mainCategoryID = mainCategoryID
        record.subCategoryID = subCategoryID
        currentUnmatchedIndex += 1
        importProgress = Double(currentUnmatchedIndex) / Double(unmatchedRecords.count)

        if currentUnmatchedIndex >= unmatchedRecords.count {
            finishImport()
        }
    }

    func skipRecord() {
        currentUnmatchedIndex += 1
        importProgress = Double(currentUnmatchedIndex) / Double(unmatchedRecords.count)

        if currentUnmatchedIndex >= unmatchedRecords.count {
            finishImport()
        }
    }

    func finishImport() {
        // 保存所有记录到数据库
        Task {
            do {
                try await billRepository.addBatch(parsedRecords)
                stage = .completed
            } catch {
                stage = .failed("保存失败：\(error.localizedDescription)")
            }
        }
    }

    func cancelImport() {
        stage = .selectSource
        parsedRecords = []
        unmatchedRecords = []
        duplicateRecords = []
        currentUnmatchedIndex = 0
        importProgress = 0
    }

    // MARK: - Private

    private func startParsing(fileURL: URL) async {
        importProgress = 0.2

        guard let format = selectedFormat else {
            stage = .failed("未选择文件来源")
            return
        }

        // 选择对应的解析器
        let parser: BillParser
        let fileExt = fileURL.pathExtension.lowercased()

        if fileExt == "xlsx" {
            let xlsxParser = XLSXParser()
            // 将 xlsx 解析结果包装为 BillParser
            parser = XLSXBridgeParser(xlsxParser: xlsxParser, format: format)
        } else if format == .wechat {
            parser = WeChatParser()
        } else {
            parser = AlipayParser()
        }

        importOrchestrator = ImportOrchestrator(billParser: parser, billRepository: billRepository)

        importProgress = 0.4

        do {
            let result = try await importOrchestrator!.execute(
                fileURL: fileURL,
                format: format,
                deduplicate: shouldDeduplicate
            )

            parsedRecords = result.records
            duplicateRecords = result.duplicates
            importProgress = 0.6

            // 自动分类
            stage = .autoCategorizing
            let (matched, unmatched) = try await autoCategorizeUseCase.batchCategorize(records: parsedRecords)
            importProgress = 0.8

            // 构建匹配记录展示数据
            matchedRecords = []
            for (record, mainID, subID) in matched {
                let mainName = await getMainCategoryName(id: mainID) ?? "未知"
                let subName = await getSubCategoryName(id: subID) ?? "未知"
                matchedRecords.append((record, mainName, subName))
            }

            unmatchedRecords = unmatched

            if unmatched.isEmpty {
                finishImport()
            } else {
                currentUnmatchedIndex = 0
                stage = .manualCategorize
                availableMainCategories = (try? await categoryRepo.fetchMainCategories()) ?? []
                if let firstMain = availableMainCategories.first {
                    selectedMainCategoryID = firstMain.id
                    availableSubCategories = (try? await categoryRepo.fetchSubCategories(for: firstMain.id)) ?? []
                }
            }
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    func selectMainCategoryForManual(id: UUID) {
        selectedMainCategoryID = id
        Task {
            availableSubCategories = (try? await categoryRepo.fetchSubCategories(for: id)) ?? []
            selectedSubCategoryID = availableSubCategories.first?.id
        }
    }

    private func getMainCategoryName(id: UUID) async -> String? {
        let categories = (try? await categoryRepo.fetchMainCategories()) ?? []
        return categories.first(where: { $0.id == id })?.name
    }

    private func getSubCategoryName(id: UUID) async -> String? {
        let subs = (try? await categoryRepo.fetchAllSubCategories()) ?? []
        return subs.first(where: { $0.id == id })?.name
    }
}

// MARK: - XLSX 桥接解析器

/// 将 XLSXParser 包装为 BillParser 协议
class XLSXBridgeParser: BillParser {
    private let xlsxParser: XLSXParser
    private let format: FileFormat

    init(xlsxParser: XLSXParser, format: FileFormat) {
        self.xlsxParser = xlsxParser
        self.format = format
    }

    func parse(fileURL: URL, format: FileFormat) async throws -> [RawImportRecord] {
        let (_, rows) = try xlsxParser.parse(fileURL: fileURL)

        return rows.map { row in
            RawImportRecord(
                transactionTime: row.indices.contains(0) ? row[0] : "",
                typeRaw: row.indices.contains(1) ? row[1] : "",
                amountRaw: row.indices.contains(2) ? row[2] : "",
                merchantName: row.indices.contains(3) ? row[3] : "",
                productDescription: row.indices.contains(4) ? row[4] : ""
            )
        }
    }
}
