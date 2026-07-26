import SwiftUI
import UIKit

/// App 根容器，顶部药丸选栏 + 功能页内容
struct AppShellView: View {
    @State private var selectedFeature: Feature = .accounting

    enum Feature: String, CaseIterable, Identifiable {
        case accounting = "记账"
        case journal   = "日志"
        case plan      = "计划"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .accounting: return "dollarsign.circle"
            case .journal:   return "note.text"
            case .plan:      return "calendar"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopFeatureBar(selectedFeature: $selectedFeature)
                .padding(.top, safeAreaTop)
                .padding(.bottom, 8)

            Divider()

            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.all, edges: .top)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedFeature {
        case .accounting:
            MainTabView()
        case .journal:
            PlaceholderFeatureView(feature: .journal)
        case .plan:
            PlaceholderFeatureView(feature: .plan)
        }
    }

    private var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }
}
