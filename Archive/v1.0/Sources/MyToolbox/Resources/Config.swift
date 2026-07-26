import Foundation

/// 应用配置常量
/// 云端服务器地址等运行时配置放在此处，不硬编码在业务代码里
enum Config {
    /// 云端服务器地址（预留，暂未实现）
    static let cloudServerURL: String = ""

    /// 默认去重开关
    static let defaultDeduplicateEnabled: Bool = true

    /// 日期格式
    static let dateFormat: String = "yyyy-MM-dd HH:mm:ss"

    /// 支持的导入文件类型
    static let supportedImportExtensions: [String] = ["csv", "xlsx"]
}
