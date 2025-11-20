# 点赞和评论功能实现说明

## ✨ 新增功能

成功为短视频页面添加了完整的点赞和评论功能，包括UI和后端交互。

## 🎯 功能特性

### 1. 点赞功能 ❤️

#### 功能描述
- 点击点赞按钮即可点赞/取消点赞
- 实时更新点赞数量和状态
- 乐观更新UI（先更新界面，再调用API）
- 失败时自动恢复原状态

#### 交互效果
- **未点赞**: 空心❤️图标，白色
- **已点赞**: 实心❤️图标，红色
- **点击**: 立即切换状态和颜色
- **动画**: 平滑过渡效果

#### API接口
```
POST   /api/moments/{momentId}/like      # 点赞
DELETE /api/moments/{momentId}/like      # 取消点赞

Response:
  code: 200 表示成功
```

#### 实现逻辑
```dart
Future<void> _likeVideo(int index) async {
  final video = _videos[index];
  final newLikeStatus = !video.isLiked;

  // 1. 乐观更新 UI
  setState(() {
    _videos[index] = video.copyWith(
      isLiked: newLikeStatus,
      likeCount: video.likeCount + (newLikeStatus ? 1 : -1),
    );
  });

  // 2. 调用API
  try {
    final response = await _apiService.likeVideo(
      videoId: video.id,
      like: newLikeStatus,
    );

    // 3. 如果失败，恢复原状态
    if (!response.success) {
      setState(() {
        _videos[index] = video;
      });
    }
  } catch (e) {
    // 异常时恢复原状态
    setState(() {
      _videos[index] = video;
    });
  }
}
```

### 2. 评论功能 💬

#### 功能描述
- 查看视频的所有评论
- 发表新评论
- 实时更新评论数量
- 美观的评论UI界面

#### UI界面

**评论页面（底部弹窗）**:
```
┌─────────────────────────────┐
│ 10条评论              ×     │  ← 标题栏
├─────────────────────────────┤
│ 👤 用户A                    │
│    这个视频太棒了！          │
│    2分钟前                  │
├─────────────────────────────┤
│ 👤 用户B                    │
│    说得对！                 │
│    5分钟前                  │
├─────────────────────────────┤
│ ...更多评论...              │
├─────────────────────────────┤
│ [说点什么...     ] [发送]   │  ← 输入栏
└─────────────────────────────┘
```

#### API接口

**获取评论列表**:
```
GET /api/moments/{momentId}/comments?page=0&size=20

Response:
  - List<Comment> 评论列表
```

**发表评论**:
```
POST /api/moments/{momentId}/comments

Request:
{
  "content": "说得对！"
}

Response:
{
  "id": 1,
  "momentId": 10,
  "userId": 5,
  "username": "testuser",
  "nickname": "测试用户",
  "avatarUrl": "http://example.com/avatar.jpg",
  "content": "说得对！",
  "createdAt": "2025-11-20T03:39:36.039Z",
  "updatedAt": "2025-11-20T03:39:36.039Z"
}
```

#### 评论页面功能

**标题栏**:
- 显示评论总数
- 关闭按钮（返回评论数给上一页）

**评论列表**:
- 头像（支持自定义头像或首字母头像）
- 昵称
- 评论内容
- 相对时间（刚刚、5分钟前、2小时前等）
- 滚动加载

**输入栏**:
- 圆角输入框
- 发送按钮
- 发送中状态（显示loading）
- 支持回车发送

**空状态**:
- 友好的空状态提示
- 图标 + 文案

## 📁 文件结构

### 新增文件

```
lib/
├── models/
│   └── comment.dart                    # 评论模型 ✨ 新建
├── pages/
│   └── video/
│       ├── short_video_page.dart       # 短视频页面（已更新）
│       └── video_comment_page.dart     # 评论页面 ✨ 新建
└── services/
    └── api_service.dart                # API服务（已更新）
```

### 修改的文件

```
✏️ lib/pages/video/short_video_page.dart
   - 添加评论功能入口
   - 连接评论页面
   - 更新评论数

✏️ lib/services/api_service.dart
   - 添加获取评论列表接口
   - 添加发表评论接口
   - 点赞接口已存在（确认正常工作）
```

## 🎨 UI设计

### 点赞按钮

**未点赞状态**:
```dart
Icon(
  Icons.favorite_border,  // 空心图标
  color: Colors.white,    // 白色
  size: 28,
)
```

**已点赞状态**:
```dart
Icon(
  Icons.favorite,         // 实心图标
  color: Colors.red,      // 红色
  size: 28,
)
```

### 评论按钮

```dart
_buildActionButton(
  icon: Icons.comment,
  label: _formatCount(video.commentCount),
  onTap: () => _commentVideo(index),
)
```

### 评论页面样式

**容器**:
- 高度：屏幕高度的70%
- 圆角：顶部20px
- 背景：白色

**输入框**:
- 圆角：20px
- 背景：灰色（`Colors.grey[100]`）
- 占位符："说点什么..."

**发送按钮**:
- 圆角：16px
- 背景：主题色
- 文字：白色，加粗

## 🔄 交互流程

### 点赞流程

```
用户点击点赞按钮
    ↓
立即更新UI（乐观更新）
  - 图标：空心 ↔ 实心
  - 颜色：白色 ↔ 红色
  - 数量：±1
    ↓
调用API
    ↓
[成功] → 保持UI状态
[失败] → 恢复原UI状态
    ↓
完成
```

### 评论流程

```
用户点击评论按钮
    ↓
打开评论页面（底部弹窗）
    ↓
加载评论列表
    ↓
显示评论内容
    ↓
用户输入评论
    ↓
点击发送
    ↓
调用API发表评论
    ↓
[成功] → 
  - 新评论插入顶部
  - 更新评论数
  - 清空输入框
  - 滚动到顶部
[失败] → 显示错误提示
    ↓
用户关闭页面
    ↓
返回新的评论数给上一页
    ↓
更新短视频页面的评论数
    ↓
完成
```

## 💡 技术亮点

### 1. 乐观更新

**点赞使用乐观更新**，先更新UI，再调用API：
- ✅ 用户体验好：立即响应，无延迟
- ✅ 流畅度高：不需要等待网络请求
- ✅ 失败回滚：API失败时自动恢复

### 2. 状态同步

评论页面关闭时返回最新评论数：
```dart
final result = await showModalBottomSheet<int>(...);

if (result != null && result != video.commentCount) {
  setState(() {
    _videos[index] = video.copyWith(
      commentCount: result,
    );
  });
}
```

### 3. 时间格式化

智能显示相对时间：
```dart
String _formatTime(DateTime time) {
  final difference = now.difference(time);
  
  if (difference.inSeconds < 60) return '刚刚';
  if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
  if (difference.inHours < 24) return '${difference.inHours}小时前';
  if (difference.inDays < 7) return '${difference.inDays}天前';
  return '${time.month}-${time.day}';
}
```

### 4. 空状态处理

评论列表为空时显示友好提示：
```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      children: [
        Icon(Icons.comment_outlined, size: 64),
        Text('还没有评论'),
        Text('快来发表第一条评论吧~'),
      ],
    ),
  );
}
```

### 5. 输入验证

发表评论前验证内容：
```dart
Future<void> _postComment() async {
  final content = _commentController.text.trim();
  
  if (content.isEmpty) {
    EasyLoading.showToast('请输入评论内容');
    return;
  }
  
  // ... 发送评论
}
```

## 🧪 测试场景

### 测试1: 点赞功能

**步骤**:
```
1. 进入短视频页面
2. 点击点赞按钮（空心❤️）
3. ✅ 应该立即变成实心红色❤️
4. ✅ 点赞数+1
5. 再次点击
6. ✅ 应该变回空心白色❤️
7. ✅ 点赞数-1
```

**网络异常测试**:
```
1. 断开网络
2. 点击点赞
3. ✅ UI立即更新
4. ✅ API失败后UI恢复原状态
5. ✅ 显示错误提示
```

### 测试2: 评论功能

**查看评论**:
```
1. 点击评论按钮
2. ✅ 弹出评论页面
3. ✅ 显示评论数量标题
4. ✅ 加载评论列表
5. ✅ 显示头像、昵称、内容、时间
```

**发表评论**:
```
1. 在评论页面输入"测试评论"
2. 点击发送
3. ✅ 显示发送中状态
4. ✅ 评论成功后出现在列表顶部
5. ✅ 输入框清空
6. ✅ 自动滚动到顶部
7. ✅ 评论数+1
```

**空输入测试**:
```
1. 不输入内容直接点发送
2. ✅ 显示"请输入评论内容"提示
3. ✅ 不会发送请求
```

**关闭页面**:
```
1. 点击关闭按钮
2. ✅ 评论页面关闭
3. ✅ 短视频页面的评论数更新
```

### 测试3: 空状态

**无评论时**:
```
1. 打开一个没有评论的视频
2. 点击评论按钮
3. ✅ 显示空状态图标和文案
4. ✅ "还没有评论"
5. ✅ "快来发表第一条评论吧~"
```

## 📊 数据模型

### Comment 模型

```dart
class Comment {
  final int id;              // 评论ID
  final int momentId;        // 视频ID（动态ID）
  final int userId;          // 用户ID
  final String username;     // 用户名
  final String nickname;     // 昵称
  final String? avatarUrl;   // 头像URL
  final String content;      // 评论内容
  final DateTime createdAt;  // 创建时间
  final DateTime updatedAt;  // 更新时间
}
```

## ⚙️ 配置说明

### API配置

确保以下接口在服务器端已实现：

1. **点赞接口**
   - `POST /api/moments/{momentId}/like` - 点赞
   - `DELETE /api/moments/{momentId}/like` - 取消点赞

2. **评论接口**
   - `GET /api/moments/{momentId}/comments` - 获取评论列表
   - `POST /api/moments/{momentId}/comments` - 发表评论

### 参数说明

**获取评论列表**:
- `page`: 页码（从0开始）
- `size`: 每页数量（默认20）

**发表评论**:
- `content`: 评论内容（必填）

## 🎉 功能完成度

### ✅ 已完成

- ✅ 点赞/取消点赞功能
- ✅ 点赞状态UI更新
- ✅ 点赞数量实时更新
- ✅ 乐观更新机制
- ✅ 评论列表查看
- ✅ 发表评论功能
- ✅ 评论数量更新
- ✅ 评论页面UI
- ✅ 输入验证
- ✅ 空状态处理
- ✅ 时间格式化
- ✅ 错误处理
- ✅ Loading状态

### 🔄 可扩展功能

以下功能可以在未来添加：

1. **评论点赞** - 给评论点赞
2. **回复评论** - 回复其他用户的评论
3. **删除评论** - 删除自己的评论
4. **评论表情** - 支持emoji表情
5. **@用户** - 在评论中@其他用户
6. **评论图片** - 支持评论时上传图片
7. **评论分页** - 评论列表分页加载
8. **评论排序** - 按时间/热度排序

## 📱 用户体验

### 点赞体验

**优点**:
- ⚡ 即时反馈，无延迟
- 🎨 视觉效果明显（颜色+图标变化）
- ♻️ 失败自动恢复
- 📱 流畅不卡顿

### 评论体验

**优点**:
- 📝 输入方便，发送快捷
- 👀 评论清晰易读
- 🕐 时间显示友好
- 🎯 空状态引导明确
- ✨ 动画流畅自然

## 🐛 常见问题

### Q1: 点赞按钮点击后没反应？

**可能原因**:
1. API接口未实现
2. 网络问题
3. 权限不足

**排查方法**:
```dart
// 查看控制台日志
debugPrint('点赞短视频: momentId=$videoId');
debugPrint('点赞成功');  // 或错误信息
```

### Q2: 评论发送失败？

**可能原因**:
1. 评论内容为空
2. API接口问题
3. 未登录

**解决方法**:
- 检查输入内容
- 查看错误提示
- 确认登录状态

### Q3: 评论数不更新？

**原因**: 评论页面返回值未正确处理

**解决**: 确保页面关闭时返回最新评论数
```dart
Navigator.pop(context, _commentCount);
```

## 📚 相关文档

- `lib/models/comment.dart` - 评论模型定义
- `lib/pages/video/video_comment_page.dart` - 评论页面实现
- `lib/services/api_service.dart` - API接口实现
- `lib/pages/video/short_video_page.dart` - 短视频页面

---

**更新时间**: 2025-11-20  
**版本**: v1.0  
**功能状态**: ✅ 完成并可用

