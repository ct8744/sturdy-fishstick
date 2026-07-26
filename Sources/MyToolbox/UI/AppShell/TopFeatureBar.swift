import SwiftUI

/// 顶部药丸形状的功能选择栏
struct TopFeatureBar: View {
    @Binding var selectedFeature: AppShellView.Feature

    private let features = AppShellView.Feature.allCases

    var body: some View {
        GeometryReader { geo in
            let segmentWidth = geo.size.width / CGFloat(features.count)
            let selectedIndex = features.firstIndex(of: selectedFeature) ?? 0

            ZStack(alignment: .leading) {
                // 背景
                Capsule()
                    .fill(.quaternary.opacity(0.5))
                    .frame(height: 38)

                // 滑动的选中胶囊
                Capsule()
                    .fill(.tint)
                    .frame(width: segmentWidth - 4, height: 34)
                    .offset(x: segmentWidth * CGFloat(selectedIndex) + 2)

                // 按钮
                HStack(spacing: 0) {
                    ForEach(features) { feature in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedFeature = feature
                            }
                        }) {
                            Label(feature.rawValue, systemImage: feature.icon)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selectedFeature == feature ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 38)
        }
        .frame(height: 38)
        .padding(.horizontal)
    }
}
