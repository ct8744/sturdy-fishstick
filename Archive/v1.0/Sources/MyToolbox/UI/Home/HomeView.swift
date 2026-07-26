import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showAddRecord = false
    @State private var showImport = false
    @State private var showCategoryManage = false
    @State private var showExport = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let billRepo = BillRepositoryImpl(modelContext: modelContext)
        let categoryRepo = CategoryRepositoryImpl(modelContext: modelContext)
        let summaryUseCase = MonthlySummaryUseCase(billRepository: billRepo)
        _viewModel = State(initialValue: HomeViewModel(
            summaryUseCase: summaryUseCase,
            billRepository: billRepo,
            categoryRepo: categoryRepo
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 本月总览卡片
                    MonthlySummaryCard(summary: viewModel.summary)

                    // 分类排行
                    CategoryRankingView(
                        rankingLevel: viewModel.rankingLevel,
                        rankingItems: viewModel.rankingItems,
                        onToggleLevel: { viewModel.toggleRankingLevel() }
                    )

                    // 近期明细
                    RecentRecordsList(records: viewModel.recentRecords)

                    // 底部操作栏
                    bottomActionBar
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的工具箱")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") {
                        showCategoryManage = true
                    }
                }
            }
            .sheet(isPresented: $showAddRecord) {
                AddRecordView(modelContext: modelContext)
            }
            .navigationDestination(isPresented: $showImport) {
                ImportView(modelContext: modelContext)
            }
            .navigationDestination(isPresented: $showCategoryManage) {
                CategoryManageView(modelContext: modelContext)
            }
            .navigationDestination(isPresented: $showExport) {
                ExportView(modelContext: modelContext)
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            actionButton(title: "记一笔", icon: "plus.circle.fill", color: .blue) {
                showAddRecord = true
            }
            actionButton(title: "导入", icon: "square.and.arrow.down.fill", color: .green) {
                showImport = true
            }
            actionButton(title: "导出", icon: "square.and.arrow.up.fill", color: .orange) {
                showExport = true
            }
        }
        .padding(.vertical, 8)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(color)
    }
}
