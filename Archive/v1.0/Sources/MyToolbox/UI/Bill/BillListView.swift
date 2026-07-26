import SwiftUI
import SwiftData

struct BillListView: View {
    @State private var viewModel: BillListViewModel
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let billRepo = BillRepositoryImpl(modelContext: modelContext)
        let categoryRepo = CategoryRepositoryImpl(modelContext: modelContext)
        _viewModel = State(initialValue: BillListViewModel(
            billRepository: billRepo,
            categoryRepo: categoryRepo
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月份选择器
                monthPicker

                // 类型筛选
                typeFilterBar

                // 列表
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.records) { record in
                            BillRowView(
                                record: record,
                                mainCategoryName: viewModel.mainCategoryNames[record.mainCategoryID ?? UUID()] ?? nil,
                                subCategoryName: viewModel.subCategoryNames[record.subCategoryID ?? UUID()] ?? nil
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteRecord(viewModel.records[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("账单")
            .task {
                await viewModel.onAppear()
            }
        }
    }

    private var monthPicker: some View {
        HStack {
            Button(action: {
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: viewModel.selectedMonth) {
                    viewModel.switchToMonth(prev)
                }
            }) {
                Image(systemName: "chevron.left")
            }

            Text(viewModel.selectedMonth, format: .dateTime.year().month())
                .font(.headline)
                .frame(maxWidth: .infinity)

            Button(action: {
                if let next = Calendar.current.date(byAdding: .month, value: 1, to: viewModel.selectedMonth) {
                    viewModel.switchToMonth(next)
                }
            }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var typeFilterBar: some View {
        HStack(spacing: 8) {
            filterChip(title: "全部", isSelected: viewModel.selectedTypeFilter == nil) {
                viewModel.toggleTypeFilter(nil)
            }
            filterChip(title: "支出", isSelected: viewModel.selectedTypeFilter == .expense) {
                viewModel.toggleTypeFilter(.expense)
            }
            filterChip(title: "收入", isSelected: viewModel.selectedTypeFilter == .income) {
                viewModel.toggleTypeFilter(.income)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无账单",
            systemImage: "receipt",
            description: Text("点击 + 记一笔，或导入账单文件")
        )
    }
}

// MARK: - BillRowView

struct BillRowView: View {
    let record: BillRecord
    let mainCategoryName: String?
    let subCategoryName: String?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.merchantName.isEmpty ? "未记录" : record.merchantName)
                    .font(.subheadline.weight(.medium))

                if let main = mainCategoryName, let sub = subCategoryName {
                    Text("\(main)·\(sub)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !record.tag.isEmpty {
                    Text(record.tag)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(record.amount, type: record.type))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(record.type == .expense ? .red : .green)

                Text(record.transactionTime, format: .dateTime.month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatAmount(_ amount: Decimal, type: TransactionType) -> String {
        let value = (amount as NSDecimalNumber).doubleValue
        let prefix = type == .expense ? "-" : "+"
        return "\(prefix)¥\(String(format: "%.2f", value))"
    }
}
