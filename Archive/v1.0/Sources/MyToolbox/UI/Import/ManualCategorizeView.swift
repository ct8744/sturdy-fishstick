import SwiftUI

struct ManualCategorizeView: View {
    @State var viewModel: ImportViewModel

    var body: some View {
        VStack(spacing: 20) {
            // 进度指示
            Text("第 \(viewModel.currentUnmatchedIndex + 1)/\(viewModel.unmatchedRecords.count) 条")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            // 当前记录信息
            if viewModel.currentUnmatchedIndex < viewModel.unmatchedRecords.count {
                let record = viewModel.unmatchedRecords[viewModel.currentUnmatchedIndex]

                VStack(spacing: 8) {
                    HStack {
                        Text("商户：")
                            .foregroundStyle(.secondary)
                        Text(record.merchantName.isEmpty ? "未知" : record.merchantName)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("金额：")
                            .foregroundStyle(.secondary)
                        Text(formatAmount(record.amount, type: record.type))
                            .fontWeight(.semibold)
                            .foregroundStyle(record.type == .expense ? .red : .green)
                    }

                    HStack {
                        Text("时间：")
                            .foregroundStyle(.secondary)
                        Text(record.transactionTime, format: .dateTime.year().month().day().hour().minute())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 分类选择
            VStack(spacing: 12) {
                Picker("大类", selection: $viewModel.selectedMainCategoryID) {
                    Text("请选择").tag(nil as UUID?)
                    ForEach(viewModel.availableMainCategories, id: \.id) { cat in
                        Text(cat.name).tag(cat.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedMainCategoryID) { _, newID in
                    if let id = newID {
                        viewModel.selectMainCategoryForManual(id: id)
                    }
                }

                Picker("小类", selection: $viewModel.selectedSubCategoryID) {
                    Text("请选择").tag(nil as UUID?)
                    ForEach(viewModel.availableSubCategories, id: \.id) { sub in
                        Text(sub.name).tag(sub.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // 操作按钮
            HStack(spacing: 16) {
                Button("跳过") {
                    viewModel.skipRecord()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button("确认") {
                    if let mainID = viewModel.selectedMainCategoryID,
                       let subID = viewModel.selectedSubCategoryID {
                        viewModel.confirmCategory(mainCategoryID: mainID, subCategoryID: subID)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedSubCategoryID == nil)
            }
        }
        .padding()
    }

    private func formatAmount(_ amount: Decimal, type: TransactionType) -> String {
        let value = (amount as NSDecimalNumber).doubleValue
        let prefix = type == .expense ? "-" : "+"
        return "\(prefix)¥\(String(format: "%.2f", value))"
    }
}
