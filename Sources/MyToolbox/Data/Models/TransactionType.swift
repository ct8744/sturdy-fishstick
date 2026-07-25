import Foundation

/// 交易类型：收入 / 支出
enum TransactionType: String, Codable, CaseIterable {
    case income   // 收入
    case expense  // 支出

    var displayName: String {
        switch self {
        case .income:  return "收入"
        case .expense: return "支出"
        }
    }
}
