import SwiftUI

struct SourceSelectionView: View {
    let onSelect: (FileFormat) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("选择账单来源")
                .font(.title2.weight(.semibold))
                .padding(.top, 40)

            VStack(spacing: 16) {
                sourceButton(
                    icon: "message.fill",
                    title: "微信账单",
                    color: .green,
                    format: .wechat
                )

                sourceButton(
                    icon: "creditcard.fill",
                    title: "支付宝账单",
                    color: .blue,
                    format: .alipay
                )

                sourceButton(
                    icon: "doc.text.fill",
                    title: "自定义模板",
                    color: .orange,
                    format: .custom
                )
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func sourceButton(icon: String, title: String, color: Color, format: FileFormat) -> some View {
        Button(action: { onSelect(format) }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32)

                Text(title)
                    .font(.body.weight(.medium))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.03), radius: 2)
        }
        .buttonStyle(.plain)
    }
}
