import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class CategoryManageViewModel {
    var mainCategories: [MainCategory] = []
    var selectedMainCategory: MainCategory?
    var subCategories: [SubCategory] = []

    // 编辑状态
    var isEditing: Bool = false
    var editingItem: EditingItem?
    var editingText: String = ""

    // 关键词管理
    var keywordMaps: [KeywordMap] = []
    var isShowingKeywordEditor: Bool = false
    var editingKeywordText: String = ""

    // 删除确认
    var showDeleteConfirmation: Bool = false
    var itemToDelete: DeletingItem?

    enum EditingItem: Identifiable {
        case addMain
        case renameMain(MainCategory)
        case addSub(MainCategory)
        case renameSub(SubCategory)

        var id: String {
            switch self {
            case .addMain:                    return "addMain"
            case .renameMain(let c):          return "renameMain-\(c.id)"
            case .addSub(let c):              return "addSub-\(c.id)"
            case .renameSub(let c):           return "renameSub-\(c.id)"
            }
        }
    }

    enum DeletingItem {
        case main(MainCategory)
        case sub(SubCategory)
    }

    private let manageUseCase: ManageCategoryUseCase
    private let keywordRepo: KeywordMapRepository
    private let categoryRepo: CategoryRepository

    init(
        manageUseCase: ManageCategoryUseCase,
        keywordRepo: KeywordMapRepository,
        categoryRepo: CategoryRepository
    ) {
        self.manageUseCase = manageUseCase
        self.keywordRepo = keywordRepo
        self.categoryRepo = categoryRepo
    }

    func loadCategories() async {
        mainCategories = (try? await categoryRepo.fetchMainCategories()) ?? []
        if selectedMainCategory == nil, let first = mainCategories.first {
            await selectMainCategory(first)
        }
    }

    func selectMainCategory(_ category: MainCategory) async {
        selectedMainCategory = category
        subCategories = (try? await categoryRepo.fetchSubCategories(for: category.id)) ?? []
    }

    // MARK: - 添加

    func addMainCategory(name: String) {
        Task {
            try await manageUseCase.createMainCategory(name: name)
            await loadCategories()
        }
    }

    func addSubCategory(name: String, to main: MainCategory) {
        Task {
            try await manageUseCase.createSubCategory(name: name, mainCategoryID: main.id)
            await selectMainCategory(main)
        }
    }

    // MARK: - 删除

    func requestDeleteMainCategory(_ category: MainCategory) {
        itemToDelete = .main(category)
        showDeleteConfirmation = true
    }

    func requestDeleteSubCategory(_ category: SubCategory) {
        itemToDelete = .sub(category)
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let item = itemToDelete else { return }
        showDeleteConfirmation = false

        Task {
            switch item {
            case .main(let category):
                try await manageUseCase.deleteMainCategory(id: category.id)
                if selectedMainCategory?.id == category.id {
                    selectedMainCategory = nil
                    subCategories = []
                }
            case .sub(let category):
                try await manageUseCase.deleteSubCategory(id: category.id)
                if let main = selectedMainCategory {
                    await selectMainCategory(main)
                }
            }
            await loadCategories()
        }

        itemToDelete = nil
    }

    func cancelDelete() {
        showDeleteConfirmation = false
        itemToDelete = nil
    }

    // MARK: - 重命名

    func beginRenameMain(_ category: MainCategory) {
        editingItem = .renameMain(category)
        editingText = category.name
    }

    func beginRenameSub(_ category: SubCategory) {
        editingItem = .renameSub(category)
        editingText = category.name
    }

    func submitRename() {
        guard let item = editingItem, !editingText.isEmpty else { return }

        Task {
            switch item {
            case .renameMain(let category):
                guard category.name != editingText else { break }
                try await manageUseCase.renameMainCategory(id: category.id, newName: editingText)
            case .renameSub(let category):
                guard category.name != editingText else { break }
                try await manageUseCase.renameSubCategory(id: category.id, newName: editingText)
            default:
                break
            }
            editingItem = nil
            editingText = ""
            await loadCategories()
        }
    }

    func cancelEditing() {
        editingItem = nil
        editingText = ""
    }

    // MARK: - 关键词管理

    func showKeywordEditor(for subCategory: SubCategory) {
        isShowingKeywordEditor = true
        editingKeywordText = ""
        Task {
            keywordMaps = (try? await keywordRepo.fetchAll())?
                .filter { $0.subCategoryID == subCategory.id } ?? []
        }
    }

    func addKeyword(_ keyword: String, for subCategoryID: UUID) {
        guard !keyword.isEmpty else { return }
        Task {
            let map = KeywordMap(keyword: keyword, subCategoryID: subCategoryID, priority: 0)
            try await keywordRepo.add(map)
            keywordMaps.append(map)
            editingKeywordText = ""
        }
    }

    func deleteKeyword(_ map: KeywordMap) {
        Task {
            try await keywordRepo.delete(map)
            keywordMaps.removeAll { $0.id == map.id }
        }
    }
}
