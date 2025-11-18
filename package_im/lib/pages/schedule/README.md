# 📅 日程管理功能

## 功能概述

一个功能完整的日程管理系统，支持创建、编辑、删除和查看日程安排。

## ✨ 主要特性

### 1. 日历视图
- 📆 月历显示，可左右切换月份
- 🎯 当天高亮显示
- 📍 有日程的日期显示小圆点标记
- ✅ 点击日期查看当天日程

### 2. 日程管理
- ➕ 创建新日程
- ✏️ 编辑现有日程
- 🗑️ 删除日程
- 💾 自动本地保存

### 3. 日程信息
- 📝 标题（必填，最多50字）
- 📄 描述（可选，最多200字）
- 📅 日期选择
- ⏰ 时间选择
- 🎨 6种颜色标签
  - 绿色（默认）
  - 蓝色
  - 红色
  - 黄色
  - 紫色
  - 橙色

## 🎨 UI设计

### 顶部头部
- 绿色渐变背景
- 显示当前选中日期
- 圆角底部设计

### 日历区域
- 白色卡片容器
- 月份切换按钮
- 7x6 网格日期显示
- 选中日期绿色背景高亮
- 今日日期绿色边框
- 有日程日期底部圆点标记

### 日程列表
- 卡片式布局
- 左侧彩色标签条
- 显示标题、时间、描述
- 右侧更多操作按钮
- 空状态提示

### 悬浮按钮
- 绿色圆形按钮
- 右下角固定位置
- 点击快速创建日程

## 🔧 技术实现

### 数据存储
- 使用 `SharedPreferences` 本地持久化
- JSON 格式序列化/反序列化
- 自动保存，无需手动触发

### 日期处理
- 使用 `intl` 包格式化日期
- 支持中文日期格式
- 自动计算每月天数和起始星期

### 状态管理
- StatefulWidget 本地状态管理
- setState 触发 UI 更新
- 实时响应用户操作

## 📱 使用方法

### 查看日程
1. 点击底部导航栏"日程"标签
2. 在日历中选择日期
3. 查看该日期下的所有日程

### 创建日程
1. 点击右下角"+"按钮
2. 填写标题（必填）
3. 选择日期和时间
4. 添加描述（可选）
5. 选择标签颜色
6. 点击"添加"保存

### 编辑日程
1. 点击日程卡片右侧"⋮"按钮
2. 选择"编辑"
3. 修改日程信息
4. 点击"保存"

### 删除日程
1. 点击日程卡片右侧"⋮"按钮
2. 选择"删除"
3. 确认删除操作

### 切换月份
- 点击日历顶部左箭头查看上月
- 点击日历顶部右箭头查看下月

## 📦 数据结构

```dart
class Schedule {
  final String id;              // 唯一标识
  final String title;           // 标题
  final String description;     // 描述
  final DateTime date;          // 日期时间
  final String color;           // 颜色（16进制字符串）
}
```

## 🚀 后续优化建议

### 功能增强
- [ ] 日程提醒通知
- [ ] 重复日程（每天/每周/每月）
- [ ] 日程分类标签
- [ ] 日程搜索功能
- [ ] 日程导出/导入
- [ ] 与云端同步

### UI 优化
- [ ] 周视图
- [ ] 列表视图
- [ ] 滑动手势切换月份
- [ ] 日程拖拽调整
- [ ] 深色模式支持

### 性能优化
- [ ] 大量日程时的分页加载
- [ ] 日历渲染优化
- [ ] 图片缓存策略

## 📝 注意事项

1. **日期格式化**：需要确保 `intl` 包已正确安装
2. **本地存储**：数据仅保存在本地，卸载应用会丢失
3. **时区处理**：使用设备本地时区
4. **中文支持**：如需完整中文日期格式，建议在 `main.dart` 中配置：

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('zh', 'CN'),
  ],
  // ... 其他配置
)
```

记得在 `pubspec.yaml` 中添加：
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

然后运行 `flutter pub get`。

## 🎯 集成到项目

日程功能已成功集成到主页 TabBar 中：

```dart
// lib/pages/home_page.dart
final List<Widget> _pages = const [
  ChatListPage(),    // 聊天
  FriendListPage(),  // 好友
  SchedulePage(),    // 日程 ✨ 新增
];
```

底部导航栏显示为第三个标签，图标为 📅 日历。

