import SwiftUI

struct ImportCompleteView: View {
    let recordCount: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("导入完成！")
                .font(.title2.weight(.semibold))

            Text("成功导入 \(recordCount) 条记录")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button("返回首页") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
