import SwiftUI
import SwiftData

/// 自定义 Tab Bar 主容器
/// 四模块入口：首页 / 账单 / 记一笔（浮起按钮）/ 我的
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home
    @State private var showAddRecord = false

    enum Tab: String, CaseIterable {
        case home   // 首页
        case bills  // 账单
        case add    // 记一笔（浮动按钮）
        case mine   // 我的

        var icon: String {
            switch self {
            case .home:  return "house"
            case .bills: return "list.bullet.rectangle"
            case .add:   return "plus.circle.fill"
            case .mine:  return "person"
            }
        }

        var title: String {
            switch self {
            case .home:  return "首页"
            case .bills: return "账单"
            case .add:   return ""
            case .mine:  return "我的"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView(modelContext: modelContext)
                case .bills:
                    BillListView(modelContext: modelContext)
                case .add:
                    Color.clear
                case .mine:
                    SettingsView(modelContext: modelContext)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 自定义 Tab Bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    if tab == .add {
                        // 居中浮动按钮
                        Spacer()
                        addButton
                        Spacer()
                    } else {
                        tabButton(tab)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddRecord) {
            AddRecordView(modelContext: modelContext)
        }
    }

    // MARK: - Tab 按钮

    private func tabButton(_ tab: Tab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .symbolVariant(selectedTab == tab ? .fill : .none)
                Text(tab.title)
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == tab ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 浮动 + 按钮

    private var addButton: some View {
        Button(action: { showAddRecord = true }) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 52, height: 52)
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .offset(y: -8)
    }
}

// MARK: - 我的 / 设置页面

struct SettingsView: View {
    let modelContext: ModelContext

    var body: some View {
        NavigationStack {
            List {
                Section("数据管理") {
                    NavigationLink {
                        CategoryManageView(modelContext: modelContext)
                    } label: {
                        Label("分类管理", systemImage: "folder")
                    }

                    NavigationLink {
                        ExportView(modelContext: modelContext)
                    } label: {
                        Label("导出账单", systemImage: "square.and.arrow.up")
                    }
                }

                Section("云端（预留）") {
                    Label("iCloud 同步", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                    Label("自动备份", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}
