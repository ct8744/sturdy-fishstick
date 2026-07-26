import Foundation

/// 账单解析器协议
protocol BillParser {
    /// 解析文件为原始导入记录
    /// - Parameters:
    ///   - fileURL: 文件 URL
    ///   - format: 文件来源格式
    /// - Returns: 原始导入记录列表
    func parse(fileURL: URL, format: FileFormat) async throws -> [RawImportRecord]
}

/// 日期解析工具
enum DateParser {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parse(_ dateString: String) -> Date? {
        dateFormatter.date(from: dateString)
            ?? dateOnlyFormatter.date(from: dateString)
    }
}
