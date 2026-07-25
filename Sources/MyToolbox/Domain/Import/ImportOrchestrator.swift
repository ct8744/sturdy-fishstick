import Foundation

/// 导入全流程编排器
/// 1. 解析文件 → 2. 映射为标准记录 → 3. 去重 → 4. 自动分类 → 5. 返回结果
class ImportOrchestrator {
    private let billParser: BillParser
    private let billRepository: BillRepository

    init(billParser: BillParser, billRepository: BillRepository) {
        self.billParser = billParser
        self.billRepository = billRepository
    }

    /// 执行完整导入流程
    func execute(
        fileURL: URL,
        format: FileFormat,
        deduplicate: Bool
    ) async throws -> ImportResult {
        // 1. 解析文件
        let rawRecords = try await billParser.parse(fileURL: fileURL, format: format)

        // 2. 映射为标准 BillRecord
        var records: [BillRecord] = []
        for raw in rawRecords {
            guard let record = try mapToBillRecord(raw: raw) else { continue }
            records.append(record)
        }

        var duplicates: [BillRecord] = []

        // 3. 去重（可选）
        if deduplicate {
            (records, duplicates) = try await performDeduplication(records: records)
        }

        // 4. 未匹配分类的记录暂不处理，等待后续自动分类
        return ImportResult(
            totalCount: rawRecords.count,
            records: records,
            matched: [],
            unmatched: records,
            duplicates: duplicates
        )
    }

    // MARK: - 字段映射

    private func mapToBillRecord(raw: RawImportRecord) throws -> BillRecord? {
        guard let time = DateParser.parse(raw.transactionTime) else {
            return nil // 时间解析失败，跳过
        }

        let type: TransactionType
        let typeClean = raw.typeRaw.trimmingCharacters(in: .whitespaces)
        if typeClean == "收入" || typeClean == "+" {
            type = .income
        } else if typeClean == "支出" || typeClean == "-" {
            type = .expense
        } else {
            return nil // 无法识别的类型
        }

        let amountClean = raw.amountRaw
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")

        guard let amount = Decimal(string: amountClean), amount > 0 else {
            return nil // 金额无效，跳过
        }

        let record = BillRecord(
            transactionTime: time,
            type: type,
            amount: amount,
            merchantName: raw.merchantName.trimmingCharacters(in: .whitespaces),
            tag: raw.productDescription.trimmingCharacters(in: .whitespaces)
        )

        return record
    }

    // MARK: - 去重逻辑

    /// 三要素去重：transactionTime + amount + merchantName
    private func performDeduplication(records: [BillRecord]) async throws -> (deduped: [BillRecord], duplicates: [BillRecord]) {
        let existing = try await billRepository.fetchAll()

        var deduped: [BillRecord] = []
        var duplicates: [BillRecord] = []

        for record in records {
            let isDuplicate = existing.contains { existingRecord in
                let sameTime = Calendar.current.isDate(existingRecord.transactionTime, equalTo: record.transactionTime, toGranularity: .minute)
                let sameAmount = existingRecord.amount == record.amount
                let sameMerchant = existingRecord.merchantName == record.merchantName
                return sameTime && sameAmount && sameMerchant
            }

            if isDuplicate {
                duplicates.append(record)
            } else {
                deduped.append(record)
            }
        }

        return (deduped, duplicates)
    }
}

// MARK: - 导入结果

struct ImportResult {
    let totalCount: Int
    let records: [BillRecord]          // 所有解析后的记录
    let matched: [BillRecord]          // 已自动匹配分类的
    let unmatched: [BillRecord]        // 未匹配分类的（需要弹窗）
    let duplicates: [BillRecord]       // 被去重标记的
}
