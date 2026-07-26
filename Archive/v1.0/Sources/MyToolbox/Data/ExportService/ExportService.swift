import Foundation

/// CSV 导出服务协议
protocol ExportService {
    /// 导出为 CSV 格式文件，返回文件本地 URL
    func exportToCSV(records: [BillRecord]) async throws -> URL
}

/// CSV 导出服务实现
class CSVExportService: ExportService {
    func exportToCSV(records: [BillRecord]) async throws -> URL {
        var csvString = "交易时间,类型,金额,大类,小类,商户名,备注标签\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for record in records {
            let time = dateFormatter.string(from: record.transactionTime)
            let type = record.type.displayName
            let amount = String(format: "%.2f", (record.amount as NSDecimalNumber).doubleValue)
            let merchant = escapeCSVField(record.merchantName)
            let tag = escapeCSVField(record.tag)

            // 大类和小类名称需要从关联查询获取，这里暂存 ID
            let line = "\(time),\(type),\(amount),,,\(merchant),\(tag)\n"
            csvString += line
        }

        // UTF-8 with BOM（确保 Excel 正确打开中文）
        var bomData = Data([0xEF, 0xBB, 0xBF])
        guard let csvData = csvString.data(using: .utf8) else {
            throw ExportError.encodeFailed
        }
        bomData.append(csvData)

        // 写入临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "账单导出_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try bomData.write(to: fileURL)

        return fileURL
    }

    /// 转义 CSV 字段（包含逗号或换行符时用双引号包裹）
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

enum ExportError: LocalizedError {
    case encodeFailed

    var errorDescription: String? {
        switch self {
        case .encodeFailed:
            return "编码导出数据失败"
        }
    }
}
