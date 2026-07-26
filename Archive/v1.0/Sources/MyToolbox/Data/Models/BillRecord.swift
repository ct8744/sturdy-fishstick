import Foundation
import SwiftData

@Model
class BillRecord {
    // 主键
    var id: UUID

    // 交易时间 — 导入时的原始时间，或用户手动输入
    var transactionTime: Date

    // 收/支类型
    var type: TransactionType  // .income 或 .expense

    // 金额 — 精确到两位小数
    var amount: Decimal

    // 分类关联 — 可为 nil（未分类）
    var mainCategoryID: UUID?
    var subCategoryID: UUID?

    // 商户名 — 导入时从文件读取，只读展示，不可编辑
    var merchantName: String

    // 备注标签 — 用户自由填写，不限内容
    var tag: String

    // 记录创建时间 — 自动填充
    var createdAt: Date

    // 导入批次 ID — 用于去重检查
    var importBatchID: UUID?

    init(
        id: UUID = UUID(),
        transactionTime: Date,
        type: TransactionType,
        amount: Decimal,
        mainCategoryID: UUID? = nil,
        subCategoryID: UUID? = nil,
        merchantName: String = "",
        tag: String = "",
        createdAt: Date = Date(),
        importBatchID: UUID? = nil
    ) {
        self.id = id
        self.transactionTime = transactionTime
        self.type = type
        self.amount = amount
        self.mainCategoryID = mainCategoryID
        self.subCategoryID = subCategoryID
        self.merchantName = merchantName
        self.tag = tag
        self.createdAt = createdAt
        self.importBatchID = importBatchID
    }
}
