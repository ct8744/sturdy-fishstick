import Foundation

/// 账单解析器工厂 — 根据文件格式和扩展名返回对应的解析器
struct BillParserFactory {

    /// 创建对应的解析器
    /// - Parameters:
    ///   - format: 导入来源格式
    ///   - fileExtension: 文件扩展名（如 "csv", "xlsx"）
    /// - Returns: 符合 BillParser 协议的解析器
    static func makeParser(format: FileFormat, fileExtension: String) -> BillParser {
        switch fileExtension.lowercased() {
        case "xlsx":
            return XLSXBridgeParser(xlsxParser: XLSXParser(), format: format)
        default:
            // CSV 解析器
            switch format {
            case .wechat:
                return WeChatParser()
            case .alipay:
                return AlipayParser()
            case .custom:
                return CustomCSVParser()
            }
        }
    }
}

/// 自定义 CSV 解析器 — 基于通用 BaseCSVParser
class CustomCSVParser: BaseCSVParser, BillParser {
    func parse(fileURL: URL, format: FileFormat) async throws -> [RawImportRecord] {
        let (headers, rows) = try parseCSV(fileURL: fileURL)
        let fields = XLSXFieldMapper.mapFields(headers: headers, format: .custom)

        guard let timeIdx = fields["transactionTime"],
              let typeIdx = fields["type"],
              let amountIdx = fields["amount"],
              let merchantIdx = fields["merchant"] else {
            throw ImportError.missingColumn("必要字段缺失")
        }

        var records: [RawImportRecord] = []
        for row in rows {
            guard row.count > max(timeIdx, typeIdx, amountIdx, merchantIdx) else { continue }
            let record = RawImportRecord(
                transactionTime: row[timeIdx],
                typeRaw: row[typeIdx],
                amountRaw: row[amountIdx],
                merchantName: row.indices.contains(merchantIdx) ? row[merchantIdx] : "",
                productDescription: row.indices.contains(fields["product"] ?? 0) && fields["product"] != nil ? row[fields["product"]!] : ""
            )
            records.append(record)
        }
        return records
    }
}
