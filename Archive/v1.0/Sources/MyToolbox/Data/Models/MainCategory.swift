import Foundation
import SwiftData

@Model
class MainCategory {
    var id: UUID
    var name: String       // 如"饮食"
    var sortOrder: Int     // 排序序号，用户拖拽排序时更新
    var iconName: String   // SF Symbol 名称，用于 UI 展示

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0,
        iconName: String = "list.bullet"
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.iconName = iconName
    }
}
