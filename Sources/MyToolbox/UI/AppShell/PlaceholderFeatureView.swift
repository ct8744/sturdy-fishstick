import SwiftUI

/// 预留功能占位视图（日志 / 计划）
struct PlaceholderFeatureView: View {
    let feature: AppShellView.Feature

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: feature.icon)
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text(feature.rawValue)
                .font(.title2.weight(.semibold))

            Text("即将上线")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.quaternary.opacity(0.5))
                )

            Spacer()
        }
    }
}
