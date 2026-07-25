import Foundation

/// 微信账单 CSV 解析器
class WeChatParser: BaseCSVParser, BillParser {
    func parse(fileURL: URL, format: FileFormat) async throws -> [RawImportRecord] {
        guard format == .wechat else {
            throw ImportError.invalidFormat
        }

        let (headers, rows) = try parseCSV(fileURL: fileURL)

        // 查找微信账单标准列
        guard let timeIdx = columnIndex(headers: headers, name: "交易时间"),
              let typeIdx = columnIndex(headers: headers, name: "收/支"),
              let amountIdx = columnIndex(headers: headers, name: "金额(元)"),
              let merchantIdx = columnIndex(headers: headers, name: "交易对方"),
              let productIdx = columnIndex(headers: headers, name: "商品") else {
            throw ImportError.invalidFormat
        }

        var records: [RawImportRecord] = []

        for row in rows {
            guard row.count > max(timeIdx, typeIdx, amountIdx, merchantIdx, productIdx) else {
                continue
            }

            let record = RawImportRecord(
                transactionTime: row[timeIdx],
                typeRaw: row[typeIdx],
                amountRaw: row[amountIdx],
                merchantName: row[merchantIdx],
                productDescription: row[productIdx]
            )
            records.append(record)
        }

        return records
    }
}
