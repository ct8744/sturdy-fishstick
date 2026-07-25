# MyToolbox — 个人记账工具

## 技术栈
- **语言**: Swift 5.9+
- **UI**: SwiftUI
- **数据**: SwiftData
- **架构**: MVVM + Clean Architecture + Micro-Function Architecture
- **最低支持**: iOS 17+
- **无第三方依赖**
- 唯一例外：`UIDocumentPickerViewController`（系统 API）

## 项目结构
```
Sources/MyToolbox/
├── App/                    # 应用入口 + 模块注册
│   ├── MyToolboxApp.swift
│   ├── MainTabView.swift
│   └── ModuleRegistry.swift
├── UI/                     # SwiftUI 视图层
│   ├── Home/               # 首页
│   ├── Bill/               # 账单列表/记一笔
│   ├── Import/             # 导入流程
│   ├── Category/           # 分类管理
│   └── Export/             # 导出
├── ViewModels/             # @Observable ViewModel
├── Domain/                 # 业务逻辑
│   ├── Import/
│   ├── Category/
│   ├── Statistics/
│   └── Export/
├── Data/                   # 数据层
│   ├── Models/             # SwiftData @Model
│   ├── Repositories/       # 协议 + 实现
│   ├── ImportEngine/       # CSV/XLSX 解析
│   ├── ExportService/
│   ├── Cloud/
│   └── SeedData/           # 默认数据
└── Resources/              # 配置
```

## Xcode 项目配置说明
因为是纯源码项目，你需要：

1. **在 Mac 上** 打开 Xcode 15+
2. 创建新项目 → iOS → App → "MyToolbox"
3. 将 `Sources/MyToolbox/` 目录下的所有 `.swift` 文件拖入 Xcode 项目
4. 确保 SwiftData 已启用（默认 iOS 17+ App 模板已包含）

或者使用 Swift Package 方式：
```bash
# 在 Xcode 中选择 File → Add Package Dependencies → 选择本目录
```

## 功能清单
- ✅ 手动记一笔（收入/支出）
- ✅ 导入微信/支付宝账单 CSV
- ✅ 导入 .xlsx 文件（纯原生解析）
- ✅ 自动分类（关键词映射）
- ✅ 手动分类确认弹窗
- ✅ 月度收支总览
- ✅ 分类排行
- ✅ 分类管理（CRUD + 拖拽排序）
- ✅ 关键词映射管理
- ✅ 导出 CSV
- ⬜ 云端同步（预留）
