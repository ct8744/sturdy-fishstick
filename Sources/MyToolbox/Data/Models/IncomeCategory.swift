import Foundation

/// 收入分类枚举（独立于支出分类体系，自由填写或选择）
enum IncomeCategory: String, Codable, CaseIterable, Identifiable {
    case salary      = "工资"
    case freelance   = "兼职"
    case invest      = "投资收益"
    case gift        = "红包/礼金"
    case refund      = "退款"
    case allowance   = "零花钱"
    case other       = "其他"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
