import Foundation

/// XLSX 桥接解析器 — 将 XLSXParser 输出的二维数组转为 [RawImportRecord]
/// 根据 FileFormat 使用对应的 XLSXFieldMapper 进行字段映射
class XLSXBridgeParser: BillParser {
    private let xlsxParser: XLSXParser
    private let format: FileFormat

    init(xlsxParser: XLSXParser, format: FileFormat) {
        self.xlsxParser = xlsxParser
        self.format = format
    }

    func parse(fileURL: URL, format: FileFormat) async throws -> [RawImportRecord] {
        let (headers, rows) = try xlsxParser.parse(fileURL: fileURL)
        let fields = XLSXFieldMapper.mapFields(headers: headers, format: format)

        guard let timeIdx = fields["transactionTime"],
              let typeIdx = fields["type"],
              let amountIdx = fields["amount"] else {
            throw ImportError.missingColumn("无法定位必要字段，请检查文件列名是否符合 \(format.displayName) 格式")
        }

        var records: [RawImportRecord] = []
        for row in rows {
            guard row.count > max(timeIdx, typeIdx, amountIdx) else { continue }

            let merchant = fields["merchant"].flatMap { row.indices.contains($0) ? row[$0] : nil } ?? ""
            let product = fields["product"].flatMap { row.indices.contains($0) ? row[$0] : nil } ?? ""

            let record = RawImportRecord(
                transactionTime: row[timeIdx],
                typeRaw: row[typeIdx],
                amountRaw: row[amountIdx],
                merchantName: merchant,
                productDescription: product
            )
            records.append(record)
        }
        return records
    }
}
