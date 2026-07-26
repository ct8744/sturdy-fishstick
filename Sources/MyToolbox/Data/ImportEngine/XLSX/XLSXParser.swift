import Foundation
import CoreXLSX

/// .xlsx 文件解析器 — 使用 CoreXLSX 库
/// CoreXLSX 提供了高层 API 直接解析 xlsx 文件，无需手动解压 ZIP 和解析 XML
class XLSXParser {

    /// 解析 xlsx 文件为行数据
    /// - Parameter fileURL: 文件 URL
    /// - Returns: 表头行 + 数据行（每行为字符串数组）
    func parse(fileURL: URL) throws -> (headers: [String], rows: [[String]]) {
        guard let file = XLSXFile(filepath: fileURL.path) else {
            throw XLSXError.cannotOpenFile
        }

        let sharedStrings = try file.parseSharedStrings()

        // 取第一个工作表
        let paths = try file.parseWorksheetPaths()
        guard let firstPath = paths.first else {
            throw XLSXError.noWorksheet
        }

        let worksheet = try file.parseWorksheet(at: firstPath)
        guard let rows = worksheet.data?.rows, !rows.isEmpty else {
            throw XLSXError.emptyFile
        }

        var parsedRows: [[String]] = []
        for row in rows {
            var cells: [String] = []
            // 按列引用字母顺序填充
            let maxColRef = row.cells.map { columnLetter(from: $0.reference) }.max() ?? 0
            var cellMap: [Int: String] = [:]

            for cell in row.cells {
                let colIdx = columnLetter(from: cell.reference)
                if let value = cell.value {
                    cellMap[colIdx] = value
                } else if cell.type == .sharedString, let stringIdxStr = cell.value, let stringIdx = Int(stringIdxStr) {
                    // 共享字符串
                    if let strings = sharedStrings {
                        let items = strings.items
                        if stringIdx < items.count,
                           let text = items[stringIdx].text {
                            cellMap[colIdx] = text
                        }
                    }
                }
            }

            for i in 0...maxColRef {
                cells.append(cellMap[i] ?? "")
            }
            parsedRows.append(cells)
        }

        let headers = parsedRows[0]
        let dataRows = Array(parsedRows.dropFirst())
        return (headers, dataRows)
    }

    /// 将列引用（如 "A", "B", "AA"）转换为数字索引（0-based）
    private func columnLetter(from reference: CellReference?) -> Int {
        guard let reference = reference else { return -1 }
        let colStr = String(describing: reference.column)
        var result = 0
        for char in colStr.uppercased().unicodeScalars {
            result = result * 26 + Int(char.value) - Int(UnicodeScalar("A").value) + 1
        }
        return result - 1 // 0-based
    }
}

enum XLSXError: LocalizedError {
    case cannotOpenFile
    case noWorksheet
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .cannotOpenFile: return "无法打开 .xlsx 文件"
        case .noWorksheet:    return "文件中没有工作表"
        case .emptyFile:      return "文件为空"
        }
    }
}
