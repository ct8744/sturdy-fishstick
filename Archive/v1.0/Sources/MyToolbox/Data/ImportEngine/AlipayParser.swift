import Foundation

/// 支付宝账单 CSV 解析器
class AlipayParser: BaseCSVParser, BillParser {
    func parse(fileURL: URL, format: FileFormat) async throws -> [RawImportRecord] {
        guard format == .alipay else {
            throw ImportError.invalidFormat
        }

        let (headers, rows) = try parseCSV(fileURL: fileURL)

        // 支付宝账单列名可能略有差异，尝试多种可能的列名
        let timeColNames = ["交易时间", "交易时间"]
        let typeColNames = ["收/支出", "收/支", "收入/支出"]
        let amountColNames = ["金额", "金额(元)"]
        let merchantColNames = ["交易对方", "交易对方"]
        let productColNames = ["商品说明", "商品"]

        guard let timeIdx = findFirstIndex(headers: headers, names: timeColNames),
              let typeIdx = findFirstIndex(headers: headers, names: typeColNames),
              let amountIdx = findFirstIndex(headers: headers, names: amountColNames),
              let merchantIdx = findFirstIndex(headers: headers, names: merchantColNames),
              let productIdx = findFirstIndex(headers: headers, names: productColNames) else {
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

    private func findFirstIndex(headers: [String], names: [String]) -> Int? {
        for name in names {
            if let idx = columnIndex(headers: headers, name: name) {
                return idx
            }
        }
        return nil
    }
}
