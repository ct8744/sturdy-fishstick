import Foundation
import SwiftData

/// 首次启动时写入默认分类体系和关键词映射
@MainActor
class DefaultDataSeeder {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 检查是否已初始化，如未初始化则写入默认数据
    func seedIfNeeded() throws {
        let descriptor = FetchDescriptor<MainCategory>()
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { return } // 已初始化

        try seedDefaultCategories()
        try seedDefaultKeywordMaps()
        try modelContext.save()
    }

    // MARK: - 默认分类（7.1 节）

    private func seedDefaultCategories() throws {
        // 饮食
        let food = MainCategory(name: "饮食", sortOrder: 0, iconName: "fork.knife")
        modelContext.insert(food)
        modelContext.insert(SubCategory(name: "饭卡", mainCategoryID: food.id, sortOrder: 0))
        modelContext.insert(SubCategory(name: "聚餐", mainCategoryID: food.id, sortOrder: 1))
        modelContext.insert(SubCategory(name: "外卖", mainCategoryID: food.id, sortOrder: 2))

        // 购物
        let shopping = MainCategory(name: "购物", sortOrder: 1, iconName: "bag")
        modelContext.insert(shopping)
        modelContext.insert(SubCategory(name: "烟", mainCategoryID: shopping.id, sortOrder: 0))
        modelContext.insert(SubCategory(name: "酒", mainCategoryID: shopping.id, sortOrder: 1))
        modelContext.insert(SubCategory(name: "饮料", mainCategoryID: shopping.id, sortOrder: 2))
        modelContext.insert(SubCategory(name: "网购", mainCategoryID: shopping.id, sortOrder: 3))

        // 车
        let car = MainCategory(name: "车", sortOrder: 2, iconName: "car")
        modelContext.insert(car)
        modelContext.insert(SubCategory(name: "车贷", mainCategoryID: car.id, sortOrder: 0))
        modelContext.insert(SubCategory(name: "充电", mainCategoryID: car.id, sortOrder: 1))
        modelContext.insert(SubCategory(name: "加油", mainCategoryID: car.id, sortOrder: 2))

        // 房
        let house = MainCategory(name: "房", sortOrder: 3, iconName: "house")
        modelContext.insert(house)
        modelContext.insert(SubCategory(name: "房贷", mainCategoryID: house.id, sortOrder: 0))
        modelContext.insert(SubCategory(name: "家居用品", mainCategoryID: house.id, sortOrder: 1))
        modelContext.insert(SubCategory(name: "物业费", mainCategoryID: house.id, sortOrder: 2))
    }

    // MARK: - 默认关键词映射（7.2 节）

    private func seedDefaultKeywordMaps() throws {
        // 先查询所有小类以获取 ID
        let subDescriptor = FetchDescriptor<SubCategory>()
        let allSubs = try modelContext.fetch(subDescriptor)

        let subMap = Dictionary(uniqueKeysWithValues: allSubs.map { ($0.name, $0.id) })

        let mappings: [(String, String, Int)] = [
            // 外卖
            ("美团外卖", "外卖", 10),
            ("饿了么", "外卖", 10),
            ("麦当劳", "外卖", 10),
            ("肯德基", "外卖", 10),
            // 聚餐
            ("海底捞", "聚餐", 10),
            // 饭卡
            ("食堂", "饭卡", 10),
            ("饭卡", "饭卡", 5),
            // 网购
            ("淘宝", "网购", 10),
            ("京东", "网购", 10),
            ("拼多多", "网购", 10),
            // 饮料
            ("星巴克", "饮料", 10),
            ("瑞幸", "饮料", 10),
            ("喜茶", "饮料", 10),
            // 加油
            ("中石化", "加油", 10),
            ("中石油", "加油", 10),
            // 充电
            ("特来电", "充电", 10),
            ("国家电网", "充电", 10),
            // 家居用品
            ("宜家", "家居用品", 10),
            // 物业费
            ("物业", "物业费", 10),
            // 房贷
            ("房贷", "房贷", 10),
        ]

        for (keyword, subName, priority) in mappings {
            guard let subID = subMap[subName] else { continue }
            let map = KeywordMap(keyword: keyword, subCategoryID: subID, priority: priority)
            modelContext.insert(map)
        }
    }
}
