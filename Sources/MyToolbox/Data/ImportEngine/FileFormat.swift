import Foundation

/// 导入文件来源类型
enum FileFormat: String, CaseIterable {
    case wechat    // 微信账单
    case alipay    // 支付宝账单
    case custom    // 自定义模板

    var displayName: String {
        switch self {
        case .wechat:  return "微信账单"
        case .alipay:  return "支付宝账单"
        case .custom:  return "自定义模板"
        }
    }
}
