import SwiftUI

struct CategoryRankingView: View {
    let rankingLevel: RankingLevel
    let rankingItems: [CategoryRankingItem]
    let onToggleLevel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题 + 切换按钮
            HStack {
                Text("分类排行")
                    .font(.headline)

                Spacer()

                Button(action: onToggleLevel) {
                    HStack(spacing: 4) {
                        Text(rankingLevel == .main ? "大类排行" : "小类排行")
                            .font(.caption)
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if rankingItems.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(rankingItems.prefix(10).enumerated()), id: \.element.categoryID) { index, item in
                    rankingRow(index: index, item: item)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private func rankingRow(index: Int, item: CategoryRankingItem) -> some View {
        HStack(spacing: 8) {
            // 排名
            Text("\(index + 1)")
                .font(.caption.weight(.medium))
                .foregroundStyle(index < 3 ? .orange : .secondary)
                .frame(width: 20)

            // 分类名
            Text(item.categoryName.isEmpty ? "未分类" : item.categoryName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // 占比条
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accentColor.opacity(0.4))
                    .frame(width: geo.size.width * CGFloat(item.percentage / 100))
            }
            .frame(height: 8)
            .frame(maxWidth: 80)

            // 百分比
            Text(String(format: "%.1f%%", item.percentage))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)

            // 金额
            Text(formatAmount(item.totalAmount))
                .font(.subheadline.weight(.medium))
                .frame(width: 70, alignment: .trailing)
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let value = (amount as NSDecimalNumber).doubleValue
        return String(format: "¥%.0f", value)
    }
}
