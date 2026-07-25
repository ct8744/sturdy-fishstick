import SwiftUI
import SwiftData

struct CategoryManageView: View {
    @State private var viewModel: CategoryManageViewModel
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let categoryRepo = CategoryRepositoryImpl(modelContext: modelContext)
        let keywordRepo = KeywordMapRepositoryImpl(modelContext: modelContext)
        let manageUseCase = ManageCategoryUseCase(categoryRepo: categoryRepo, keywordRepo: keywordRepo)
        _viewModel = State(initialValue: CategoryManageViewModel(
            manageUseCase: manageUseCase,
            keywordRepo: keywordRepo,
            categoryRepo: categoryRepo
        ))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 左侧：大类列表
                mainCategoryList

                // 右侧：小类列表
                subCategoryList
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.editingItem = .addMain
                        viewModel.editingText = ""
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("确认删除", isPresented: $viewModel.showDeleteConfirmation) {
                Button("删除", role: .destructive) { viewModel.confirmDelete() }
                Button("取消", role: .cancel) { viewModel.cancelDelete() }
            } message: {
                Text("删除后不可恢复，确定要删除吗？")
            }
            .sheet(item: $viewModel.editingItem) { item in
                editSheet(for: item)
            }
            .sheet(isPresented: $viewModel.isShowingKeywordEditor) {
                keywordEditorSheet
            }
            .task {
                await viewModel.loadCategories()
            }
        }
    }

    // MARK: - 大类列表

    private var mainCategoryList: some View {
        List(selection: $viewModel.selectedMainCategory) {
            ForEach(viewModel.mainCategories, id: \.id) { category in
                HStack {
                    Image(systemName: category.iconName)
                        .foregroundStyle(.tint)
                    Text(category.name)
                        .fontWeight(viewModel.selectedMainCategory?.id == category.id ? .semibold : .regular)
                    Spacer()
                }
                .tag(category)
                .contextMenu {
                    Button("重命名") { viewModel.beginRenameMain(category) }
                    Button("添加小类") {
                        viewModel.editingItem = .addSub(category)
                        viewModel.editingText = ""
                    }
                    Divider()
                    Button("删除", role: .destructive) { viewModel.requestDeleteMainCategory(category) }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.requestDeleteMainCategory(viewModel.mainCategories[index])
                }
            }
        }
        .listStyle(.plain)
        .frame(width: UIScreen.main.bounds.width * 0.4)
    }

    // MARK: - 小类列表

    private var subCategoryList: some View {
        Group {
            if let selected = viewModel.selectedMainCategory {
                List {
                    ForEach(viewModel.subCategories, id: \.id) { sub in
                        HStack {
                            Text(sub.name)
                            Spacer()
                        }
                        .contextMenu {
                            Button("重命名") { viewModel.beginRenameSub(sub) }
                            Button("管理关键词") { viewModel.showKeywordEditor(for: sub) }
                            Divider()
                            Button("删除", role: .destructive) { viewModel.requestDeleteSubCategory(sub) }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.requestDeleteSubCategory(viewModel.subCategories[index])
                        }
                    }
                }
                .listStyle(.plain)
                .overlay(alignment: .bottom) {
                    Button {
                        viewModel.editingItem = .addSub(selected)
                        viewModel.editingText = ""
                    } label: {
                        Label("添加小类", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "选择大类",
                    systemImage: "hand.point.left",
                    description: Text("从左侧选择一个分类")
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 编辑 Sheet

    @ViewBuilder
    private func editSheet(for item: CategoryManageViewModel.EditingItem) -> some View {
        NavigationStack {
            Form {
                TextField("名称", text: $viewModel.editingText)

                Button("保存") { viewModel.submitRename() }
                    .disabled(viewModel.editingText.isEmpty)
            }
            .navigationTitle(editTitle(for: item))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { viewModel.cancelEditing() }
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    private func editTitle(for item: CategoryManageViewModel.EditingItem) -> String {
        switch item {
        case .addMain:                    return "添加大类"
        case .renameMain:                 return "重命名大类"
        case .addSub:                     return "添加小类"
        case .renameSub:                  return "重命名小类"
        }
    }

    // MARK: - 关键词编辑器

    private var keywordEditorSheet: some View {
        NavigationStack {
            List {
                Section("添加关键词") {
                    HStack {
                        TextField("输入关键词", text: $viewModel.editingKeywordText)
                        Button("添加") {
                            // 从 keywordMaps 获取 subCategoryID
                            if let subID = viewModel.keywordMaps.first?.subCategoryID {
                                viewModel.addKeyword(viewModel.editingKeywordText, for: subID)
                            }
                        }
                        .disabled(viewModel.editingKeywordText.isEmpty)
                    }
                }

                Section("当前关键词") {
                    ForEach(viewModel.keywordMaps, id: \.id) { map in
                        HStack {
                            Text(map.keyword)
                            Spacer()
                            Button(action: { viewModel.deleteKeyword(map) }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    if viewModel.keywordMaps.isEmpty {
                        Text("暂无关键词映射")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("关键词管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { viewModel.isShowingKeywordEditor = false }
                }
            }
        }
    }
}
