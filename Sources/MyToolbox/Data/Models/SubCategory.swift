import Foundation
import SwiftData

@Model
class SubCategory {
    var id: UUID
    var name: String           // 如"外卖"
    var mainCategoryID: UUID   // 所属大类 ID
    var sortOrder: Int         // 在大类内部的排序

    init(
        id: UUID = UUID(),
        name: String,
        mainCategoryID: UUID,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.mainCategoryID = mainCategoryID
        self.sortOrder = sortOrder
    }
}
