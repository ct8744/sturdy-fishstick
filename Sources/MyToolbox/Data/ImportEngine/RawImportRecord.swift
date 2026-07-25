import Foundation

/// 解析后的中间数据结构，未映射为标准 BillRecord
struct RawImportRecord {
    var transactionTime: String
    var typeRaw: String       // "收入"/"支出" 或 "+"/"-"
    var amountRaw: String
    var merchantName: String
    var productDescription: String
}
