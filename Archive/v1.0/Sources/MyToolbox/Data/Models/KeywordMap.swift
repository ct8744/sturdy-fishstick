import Foundation
import SwiftData

@Model
class KeywordMap {
    var id: UUID
    var keyword: String            // 匹配关键词，如"美团外卖"
    var subCategoryID: UUID        // 关联的小类 ID
    var priority: Int              // 匹配优先级，值越大优先匹配

    init(
        id: UUID = UUID(),
        keyword: String,
        subCategoryID: UUID,
        priority: Int = 0
    ) {
        self.id = id
        self.keyword = keyword
        self.subCategoryID = subCategoryID
        self.priority = priority
    }
}
