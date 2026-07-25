import SwiftUI

struct RecentRecordsList: View {
    let records: [BillRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近期明细")
                .font(.headline)

            if records.isEmpty {
                Text("近7天暂无记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // 按日期分组
                let grouped = Dictionary(grouping: records) { record in
                    Calendar.current.startOfDay(for: record.transactionTime)
                }
                let sortedDates = grouped.keys.sorted(by: >)

                ForEach(sortedDates.prefix(7), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(date))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(grouped[date] ?? []) { record in
                            recordRow(record)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private func recordRow(_ record: BillRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.merchantName.isEmpty ? "未知商户" : record.merchantName)
                    .font(.subheadline.weight(.medium))
                Text(record.tag)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatAmount(record.amount, type: record.type))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(record.type == .expense ? .red : .green)
        }
        .padding(.vertical, 2)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日"
            return formatter.string(from: date)
        }
    }

    private func formatAmount(_ amount: Decimal, type: TransactionType) -> String {
        let value = (amount as NSDecimalNumber).doubleValue
        let prefix = type == .expense ? "-" : "+"
        return "\(prefix)¥\(String(format: "%.2f", value))"
    }
}
