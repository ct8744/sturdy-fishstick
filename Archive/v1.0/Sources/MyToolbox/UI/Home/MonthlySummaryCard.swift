import SwiftUI

struct MonthlySummaryCard: View {
    let summary: MonthlySummary?

    var body: some View {
        Group {
            if let summary {
                VStack(spacing: 12) {
                    // 收入 / 支出 / 结余
                    HStack(spacing: 0) {
                        summaryItem(title: "收入", amount: summary.totalIncome, color: .green)
                        Divider().frame(height: 40)
                        summaryItem(title: "支出", amount: summary.totalExpense, color: .red)
                        Divider().frame(height: 40)
                        summaryItem(title: "结余", amount: summary.balance, color: summary.balance >= 0 ? .blue : .orange)
                    }

                    Divider()

                    // 分类占比环形图
                    categoryRingChart(breakdowns: summary.categoryBreakdowns)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4)
            } else {
                loadingPlaceholder
            }
        }
    }

    private func summaryItem(title: String, amount: Decimal, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatAmount(amount))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private func categoryRingChart(breakdowns: [CategoryBreakdown]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("支出分布")
                .font(.subheadline.weight(.medium))

            if breakdowns.isEmpty {
                Text("本月暂无支出")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                // 简易柱状图展示各分类占比
                ForEach(breakdowns.prefix(5), id: \.categoryID) { breakdown in
                    HStack(spacing: 8) {
                        Text("分类")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.6))
                                .frame(width: geo.size.width * CGFloat(breakdown.percentage / 100))
                        }
                        .frame(height: 12)

                        Text(String(format: "%.1f%%", breakdown.percentage))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                    }
                }
            }
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let value = (amount as NSDecimalNumber).doubleValue
        if amount >= 0 {
            return String(format: "¥%.0f", value)
        } else {
            return String(format: "-¥%.0f", -value)
        }
    }

    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .frame(height: 120)
            .overlay {
                ProgressView()
            }
    }
}
