import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// 通用 CSV 解析器基类，提供 CSV 解析通用能力
class BaseCSVParser {
    /// 解析 CSV 文件内容为行数据
    /// - Parameter fileURL: 文件 URL
    /// - Returns: 表头行 + 数据行（每行为字符串数组）
    func parseCSV(fileURL: URL) throws -> (headers: [String], rows: [[String]]) {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        var rows = content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !rows.isEmpty else {
            throw ImportError.emptyFile
        }

        let headers = parseCSVLine(rows.removeFirst())
        let dataRows = rows.map { parseCSVLine($0) }

        return (headers, dataRows)
    }

    /// 解析单行 CSV（支持引号包裹的字段）
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            switch char {
            case "\"":
                inQuotes.toggle()
            case ",":
                if inQuotes {
                    current.append(char)
                } else {
                    fields.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                }
            default:
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))

        return fields
    }

    /// 在表头中查找指定列名的索引
    func columnIndex(headers: [String], name: String) -> Int? {
        headers.firstIndex { $0.trimmingCharacters(in: .whitespaces) == name }
    }
}

enum ImportError: LocalizedError {
    case emptyFile
    case invalidFormat
    case missingColumn(String)
    case parseFailed(String)
    case unsupportedFileType

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "文件为空"
        case .invalidFormat:
            return "文件格式不正确"
        case .missingColumn(let column):
            return "缺少必要列：\(column)"
        case .parseFailed(let detail):
            return "解析失败：\(detail)"
        case .unsupportedFileType:
            return "不支持的文件类型"
        }
    }
}
