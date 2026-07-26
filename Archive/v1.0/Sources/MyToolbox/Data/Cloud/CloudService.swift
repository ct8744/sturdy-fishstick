import Foundation

// 注意：此协议仅作定义，当前阶段不实现任何方法
protocol CloudService {
    func upload(records: [BillRecord]) async throws
    func download() async throws -> [BillRecord]
    func lastSyncTime() async throws -> Date?
}

/// 云端服务桩实现 — 所有方法抛出未实现错误
class CloudServiceStub: CloudService {
    func upload(records: [BillRecord]) async throws {
        throw CloudError.notImplemented
    }

    func download() async throws -> [BillRecord] {
        throw CloudError.notImplemented
    }

    func lastSyncTime() async throws -> Date? {
        throw CloudError.notImplemented
    }
}

enum CloudError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "云端功能尚未实现"
        }
    }
}
