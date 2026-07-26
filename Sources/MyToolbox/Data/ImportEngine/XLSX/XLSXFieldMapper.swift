import Foundation

/// .xlsx 文件字段列位置映射器
/// 根据表头名称查找对应列的索引
struct XLSXFieldMapper {

    /// 根据格式和表头行返回字段索引映射
    /// - Parameters:
    ///   - headers: 表头字符串数组
    ///   - format: 导入来源格式
    /// - Returns: 字段映射字典，key 为语义字段名，value 为列索引
    static func mapFields(headers: [String], format: FileFormat) -> [String: Int] {
        switch format {
        case .wechat:
            return mapWeChatFields(headers: headers)
        case .alipay:
            return mapAlipayFields(headers: headers)
        case .custom:
            return mapCustomFields(headers: headers)
        }
    }

    // MARK: - 微信字段映射

    private static func mapWeChatFields(headers: [String]) -> [String: Int] {
        var mapping: [String: Int] = [:]
        let rule: [(key: String, names: [String])] = [
            ("transactionTime", ["交易时间"]),
            ("type",            ["收/支"]),
            ("amount",          ["金额(元)", "金额"]),
            ("merchant",        ["交易对方"]),
            ("product",         ["商品", "商品说明"])
        ]
        for item in rule {
            if let idx = findFirstIndex(headers: headers, names: item.names) {
                mapping[item.key] = idx
            }
        }
        return mapping
    }

    // MARK: - 支付宝字段映射

    private static func mapAlipayFields(headers: [String]) -> [String: Int] {
        var mapping: [String: Int] = [:]
        let rule: [(key: String, names: [String])] = [
            ("transactionTime", ["交易时间"]),
            ("type",            ["收/支出", "收/支", "收入/支出"]),
            ("amount",          ["金额(元)", "金额"]),
            ("merchant",        ["交易对方"]),
            ("product",         ["商品说明", "商品"])
        ]
        for item in rule {
            if let idx = findFirstIndex(headers: headers, names: item.names) {
                mapping[item.key] = idx
            }
        }
        return mapping
    }

    // MARK: - 自定义字段映射

    private static func mapCustomFields(headers: [String]) -> [String: Int] {
        var mapping: [String: Int] = [:]
        let rule: [(key: String, names: [String])] = [
            ("transactionTime", ["时间", "交易时间", "日期"]),
            ("type",            ["类型", "收/支", "收支"]),
            ("amount",          ["金额", "金额(元)"]),
            ("merchant",        ["商户", "商家", "交易对方"]),
            ("product",         ["商品", "商品说明", "备注"])
        ]
        for item in rule {
            if let idx = findFirstIndex(headers: headers, names: item.names) {
                mapping[item.key] = idx
            }
        }
        return mapping
    }

    // MARK: - Helpers

    private static func findFirstIndex(headers: [String], names: [String]) -> Int? {
        for name in names {
            if let idx = headers.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == name }) {
                return idx
            }
        }
        return nil
    }
}
