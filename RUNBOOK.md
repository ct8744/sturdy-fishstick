# 把 MyToolbox 装到 iPhone 15（零 Mac 方案）

本方案：**云端 Mac 编译 → 你 Windows 上用 Sideloadly 装手机**。
你全程不需要拥有 Mac，也不需要付费 Apple 开发者账号（用免费 Apple ID 即可，App 有效期 7 天，到期重签）。

---

## 第 0 步：准备一个免费 Apple ID
如果你没有，去 https://appleid.apple.com 注册一个普通账号即可（就是平时下 App 用的那个）。

## 第 1 步：把代码推到 GitHub
本目录已经是一个 Git 仓库（已初始化、已写好 `.gitignore`）。你只需要：
1. 在 GitHub 新建一个**空**仓库（不要勾选 README/.gitignore）。
2. 本地执行（把 `你的用户名/仓库名` 换成实际地址）：
   ```bash
   cd C:\Users\cao'jie\CodeBuddy\MyToolbox
   git remote add origin https://github.com/你的用户名/仓库名.git
   git push -u origin main
   ```
   > 若分支名是 `master` 而不是 `main`，把上面 `main` 改成 `master`。

## 第 2 步：触发云端编译
- **GitHub Actions（默认已配好）**：推送后自动触发 `Build iOS IPA` 流水线。
  打开仓库页面 → **Actions** → 等绿勾完成（首次约 3–6 分钟）。
- **或 Codemagic（备选）**：登录 https://codemagic.io ，接入同一个 GitHub 仓库，
  它读取仓库里的 `codemagic.yaml` 自动构建。免费额度够个人用。

## 第 3 步：下载 IPA
- GitHub：Actions 页面 → 对应运行 → 右侧 **Artifacts** → 下载 `MyToolbox.ipa`。
- Codemagic：构建完成后在 Artifacts 里下载。

## 第 4 步：Windows 上装 Sideloadly
1. 安装 **iTunes（Windows 版）** 或 **Apple Devices / Apple Mobile Device 驱动**——Sideloadly 需要它来识别 iPhone。
   - 推荐装完整的 iTunes（含驱动）。
2. 下载安装 **Sideloadly**：https://sideloadly.io
3. 用数据线把 **iPhone 15** 连到电脑，手机上点「信任此电脑」。

## 第 5 步：把 App 装进手机
1. 打开 Sideloadly。
2. 把 `MyToolbox.ipa` 拖进 Sideloadly（或点 Browse 选择）。
3. **Apple ID** 填你的免费账号邮箱，**Password** 填密码。
   - 若开了两步验证，需要用「应用专用密码」：https://appleid.apple.com → 安全 → 生成。
4. 点 **Start**，等待出现 `Done`。
5. 手机上：打开失败的话，去
   **设置 → 通用 → VPN与设备管理 → 信任「你的 Apple ID (开发者)」**，再打开 App。

## 第 6 步：每 7 天重签
免费账号签名的 App **7 天后会打不开**。解决方法：把 iPhone 再连上电脑，
打开 Sideloadly，选同一个 IPA 点 **Start** 重新签名安装即可（半分钟的事）。
> 想彻底免重签，只能花 $99/年 开通 Apple 开发者计划。

---

## 常见问题
- **编译失败（CI 红叉）**：多半是代码本身的 Swift 报错。把 Actions 里的报错贴给我，我来修。
- **Sideloadly 报“设备数量超限”**：免费账号最多注册 3 台设备/年。去 https://developer.apple.com/account 的 Devices 里删掉不用设备再试。
- **提示“无法验证 App”**：回到「VPN与设备管理」里确认已点信任。
- **想换 App 图标**：替换 `MyToolbox/Assets.xcassets/AppIcon.appiconset/AppIcon.png`（1024×1024）后重新走第 1–5 步。

## 本地用 Xcode 验证（如果你以后有了 Mac）
在 Mac 上：`brew install xcodegen && xcodegen generate`，然后 Xcode 打开 `MyToolbox.xcodeproj`，
选你的 iPhone 15 或模拟器，Cmd+R 即可。
