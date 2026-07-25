import Foundation

/// .xlsx 文件解析器 — 纯原生实现，无第三方依赖
/// .xlsx 本质是 ZIP 压缩包，包含 XML 格式的工作表数据
class XLSXParser {
    /// 解析 xlsx 文件为行数据
    /// - Parameter fileURL: 文件 URL
    /// - Returns: 表头行 + 数据行（每行为字符串数组）
    func parse(fileURL: URL) throws -> (headers: [String], rows: [[String]]) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // 解压 xlsx (ZIP)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: fileURL, to: tempDir)

        // 读取共享字符串表
        let sharedStrings = try parseSharedStrings(from: tempDir)

        // 读取第一个工作表
        let sheetPath = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        let sheetData = try Data(contentsOf: sheetPath)
        let sheetXML = String(data: sheetData, encoding: .utf8) ?? ""

        // 解析行和列
        let rows = try parseSheetRows(xml: sheetXML, sharedStrings: sharedStrings)

        guard !rows.isEmpty else {
            throw ImportError.emptyFile
        }

        let headers = rows[0]
        let dataRows = Array(rows.dropFirst())

        return (headers, dataRows)
    }

    private func parseSharedStrings(from baseURL: URL) throws -> [String] {
        let sharedStringsPath = baseURL.appendingPathComponent("xl/sharedStrings.xml")
        guard FileManager.default.fileExists(atPath: sharedStringsPath.path) else {
            return []
        }

        let data = try Data(contentsOf: sharedStringsPath)
        let xml = String(data: data, encoding: .utf8) ?? ""
        return extractTextBetweenTags(xml, tag: "t")
    }

    private func parseSheetRows(xml: String, sharedStrings: [String]) throws -> [[String]] {
        var rows: [[String]] = []

        // 提取所有 <row> 标签内容
        let rowPattern = try NSRegularExpression(pattern: "<row[^>]*>(.*?)</row>", options: [.dotMatchesLineSeparators])
        let rowMatches = rowPattern.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))

        for rowMatch in rowMatches {
            guard let rowRange = Range(rowMatch.range(at: 1), in: xml) else { continue }
            let rowContent = String(xml[rowRange])

            var cells: [String] = []

            // 提取所有 <c> 标签
            let cellPattern = try NSRegularExpression(pattern: "<c[^>]*>(.*?)</c>", options: [.dotMatchesLineSeparators])
            let cellMatches = cellPattern.matches(in: rowContent, range: NSRange(rowContent.startIndex..., in: rowContent))

            for cellMatch in cellMatches {
                guard let cellRange = Range(cellMatch.range(at: 1), in: rowContent) else { continue }
                let cellContent = String(rowContent[cellRange])

                // 判断是否有 t="s" 属性（共享字符串类型）
                let fullCell = String(rowContent[Range(cellMatch.range, in: rowContent)!])
                let isSharedString = fullCell.contains("t=\"s\"")

                // 提取 <v> 标签中的值
                if let value = extractSingleTag(from: cellContent, tag: "v") {
                    if isSharedString, let index = Int(value), index < sharedStrings.count {
                        cells.append(sharedStrings[index])
                    } else {
                        cells.append(value)
                    }
                } else if let inlineText = extractSingleTag(from: cellContent, tag: "is") {
                    // 内联文本
                    let texts = extractTextBetweenTags(inlineText, tag: "t")
                    cells.append(texts.joined())
                } else {
                    cells.append("")
                }
            }

            rows.append(cells)
        }

        return rows
    }

    /// 提取标签中的文本内容
    private func extractTextBetweenTags(_ xml: String, tag: String) -> [String] {
        let pattern = "<\(tag)[^>]*>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        return matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: xml) else { return nil }
            return String(xml[range])
        }
    }

    /// 提取单个标签的内容
    private func extractSingleTag(from xml: String, tag: String) -> String? {
        let texts = extractTextBetweenTags(xml, tag: tag)
        return texts.first
    }
}

// MARK: - FileManager ZIP 扩展
private extension FileManager {
    /// 解压 ZIP 文件（使用 Foundation 内置的 NSFileCoordinator + 系统解压能力）
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        // 使用 Process 调用系统 unzip 命令（macOS 内置）
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", sourceURL.path, "-d", destinationURL.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw XLSXError.unzipFailed
        }
    }
}

enum XLSXError: LocalizedError {
    case unzipFailed
    case invalidXML

    var errorDescription: String? {
        switch self {
        case .unzipFailed: return "无法解压 .xlsx 文件"
        case .invalidXML:  return ".xlsx 文件内容格式不正确"
        }
    }
}
