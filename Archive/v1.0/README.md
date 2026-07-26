# MyToolbox v1.0 — 记账模块

> 存档日期：2026-07-26
> 架构版本：v1.0（初始）

## 目录结构

```
Archive/v1.0/
├── Sources/MyToolbox/    # 完整源码
│   ├── App/              # App 入口 + MainTabView + ModuleRegistry
│   ├── Data/             # Models / Repositories / ImportEngine / ExportService / Cloud / SeedData
│   ├── Domain/           # Use Cases
│   ├── ViewModels/       # ViewModel 层
│   ├── UI/               # SwiftUI 视图
│   └── Resources/        # Config
├── Package.swift         # SPM 依赖配置
└── README.md             # 本文件
```

## 架构特征

- **MVVM + Clean Architecture** 四层分层
- **SwiftData** 本地持久化（iOS 17+）
- **无第三方依赖**（.xlsx 使用原生 ZIP+XML 解析）
- **Micro-Function Architecture** 模块化设计
- 支持微信/支付宝 CSV 导入

## v1.1 变更说明

v1.1 在 Archive/v1.0/ 基础上迭代了以下变更：
- CHG-001: 顶部功能选择栏（AppShell）
- CHG-002: 收入分类体系独立化
- CHG-003: 分类管理 CRUD 修复
- CHG-004: 导入支持 .xlsx（使用 CoreXLSX）
- AMD-001: 数据变更实时刷新机制
