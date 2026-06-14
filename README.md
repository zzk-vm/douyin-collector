# 抖音内容收集器

自动归档抖音博主公开发布的内容，支持图文和视频信息的离线存储与浏览。

## 功能

- **信息流模式**：按时间线浏览所有已归档的作品
- **博主管理**：添加/移除关注的抖音博主
- **自动归档**：定期同步获取博主的最新作品
- **离线存储**：文案、图片、视频封面保存到本地数据库
- **详情查看**：图文滑动浏览、互动数据展示

## 前提条件

1. 安装 Flutter SDK（≥ 3.0.0）
   - [Flutter 官网安装指南](https://docs.flutter.dev/get-started/install)
   - 安装后运行 `flutter doctor` 确认环境正常

2. Android 开发环境
   - Android Studio（推荐）或 Android SDK 命令行工具
   - Android SDK API 33+

## 构建步骤

### 1. 创建 Flutter 项目

```bash
# 进入项目目录
cd douyin_collector

# 生成 Android/iOS 平台文件
flutter create --project-name douyin_collector --org com.example .
```

> ⚠️ 注意：如果目录中已有文件，`flutter create` 不会覆盖现有的 `lib/` 和 `pubspec.yaml` 文件。

### 2. 添加网络权限

编辑 `android/app/src/main/AndroidManifest.xml`，在 `<application>` 标签前添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 构建 APK

```bash
# 调试版（可安装测试）
flutter build apk --debug

# 发布版（更小、更快）
flutter build apk --release
```

APK 文件位置：
- 调试版: `build/app/outputs/flutter-apk/app-debug.apk`
- 发布版: `build/app/outputs/flutter-apk/app-release.apk`

### 5. 安装到手机

将 APK 传输到 Android 手机并安装。对于调试版 APK，需要先在手机设置中启用「允许安装未知来源应用」。

## 使用说明

### 添加博主
1. 点击底部「博主」标签
2. 点击右下角的「添加博主」按钮
3. 输入抖音号（如 `zhangsan` 或 `@zhangsan`）或主页链接
4. 点击「添加博主」等待查询结果

### 同步内容
- 在「信息流」或「博主」页面**下拉刷新**即可触发同步
- 同步会获取所有博主的最新作品并存入本地

### 浏览内容
- **信息流**：所有作品按时间倒序排列
- **博主页面**：点击博主进入专属归档，查看该博主的所有作品
- **作品详情**：点击卡片查看完整文案、图片、互动数据

## 项目结构

```
lib/
├── main.dart              # 入口
├── app.dart               # App 配置 + 导航
├── models/
│   ├── creator.dart        # 博主数据模型
│   └── post.dart           # 作品数据模型
├── services/
│   ├── app_state.dart      # 全局状态管理
│   ├── database.dart       # SQLite 数据库
│   ├── douyin_api.dart     # 抖音 API 服务
│   └── sync_service.dart   # 同步服务
└── screens/
    ├── home_page.dart           # 信息流
    ├── creators_page.dart       # 博主列表
    ├── creator_detail_page.dart # 博主详情
    ├── post_detail_page.dart    # 作品详情
    └── add_creator_page.dart    # 添加博主
```

## 技术说明

- **数据来源**：抖音网页版公开 API
- **本地存储**：SQLite（sqflite）
- **图片缓存**：cached_network_image
- **状态管理**：Provider
- **网络请求**：Dio + CookieJar

### 关于抖音 API

本应用通过模拟浏览器请求获取抖音公开数据。抖音 API 可能随时变更，若遇到同步失败，请检查应用更新。

抖音对公开内容的访问有一定限制（频率限制、Cookie 验证等），建议：
- 不要频繁同步（建议间隔 >5 分钟）
- 单个博主不要一次性拉取过多历史内容

## 免责声明

- 本应用**仅收集公开发布的内容**，不涉及任何隐私数据
- 请勿将收集的内容用于商业用途或二次分发
- 请遵守抖音平台的服务条款
- 本应用仅供个人学习研究使用
