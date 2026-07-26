import SwiftUI
import SwiftData

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddRecordViewModel
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let billRepo = BillRepositoryImpl(modelContext: modelContext)
        let categoryRepo = CategoryRepositoryImpl(modelContext: modelContext)
        _viewModel = State(initialValue: AddRecordViewModel(
            billRepository: billRepo,
            categoryRepo: categoryRepo
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                // 金额和类型
                Section("交易信息") {
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        TextField("金额", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }

                    Picker("类型", selection: $viewModel.type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("交易时间",
                               selection: $viewModel.transactionTime,
                               displayedComponents: [.date, .hourAndMinute])
                }

                // 分类选择
                Section("分类") {
                    if viewModel.mainCategories.isEmpty {
                        Text("请先在分类管理中创建分类")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("大类", selection: Binding(
                            get: { viewModel.selectedMainCategory },
                            set: { if let c = $0 { viewModel.selectMainCategory(c) } }
                        )) {
                            ForEach(viewModel.mainCategories, id: \.id) { cat in
                                Text(cat.name).tag(cat as MainCategory?)
                            }
                        }

                        Picker("小类", selection: Binding(
                            get: { viewModel.selectedSubCategory },
                            set: { if let c = $0 { viewModel.selectSubCategory(c) } }
                        )) {
                            ForEach(viewModel.availableSubCategories, id: \.id) { sub in
                                Text(sub.name).tag(sub as SubCategory?)
                            }
                        }
                    }
                }

                // 备注
                Section("备注标签") {
                    TextField("可选", text: $viewModel.tag)
                }

                // 保存按钮
                Section {
                    Button(action: { Task { await viewModel.save() } }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                            } else {
                                Text("保存")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isSaving)
                }
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onChange(of: viewModel.didSaveSuccessfully) { _, saved in
                if saved { dismiss() }
            }
            .alert("保存失败", isPresented: .init(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )) {
                Text(viewModel.saveError ?? "未知错误")
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
