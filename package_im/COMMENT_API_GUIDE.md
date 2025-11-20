# 动态评论API对接指南

## 📡 API接口说明

### 1. 获取评论列表

**接口地址**: `GET /api/moments/{momentId}/comments`

**请求参数**:
- `momentId` (路径参数): 动态ID（视频ID）
- `page` (查询参数): 页码，从0开始，默认0
- `size` (查询参数): 每页数量，默认20

**请求示例**:
```
GET /api/moments/10/comments?page=0&size=20
```

**响应格式**:
```json
{
  "comments": [
    {
      "id": 1,
      "momentId": 10,
      "userId": 5,
      "username": "testuser",
      "nickname": "测试用户",
      "avatarUrl": "http://example.com/avatar.jpg",
      "content": "说得对！",
      "createdAt": "2025-11-20T03:58:42.864Z",
      "updatedAt": "2025-11-20T03:58:42.864Z"
    }
  ],
  "totalElements": 50,
  "totalPages": 5,
  "currentPage": 0,
  "pageSize": 10,
  "hasNext": true,
  "hasPrevious": false
}
```

**响应字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `comments` | Array | 评论列表 |
| `comments[].id` | int | 评论ID |
| `comments[].momentId` | int | 动态ID |
| `comments[].userId` | int | 评论用户ID |
| `comments[].username` | string | 用户名 |
| `comments[].nickname` | string | 昵称 |
| `comments[].avatarUrl` | string | 头像URL（可选） |
| `comments[].content` | string | 评论内容 |
| `comments[].createdAt` | string | 创建时间（ISO 8601格式） |
| `comments[].updatedAt` | string | 更新时间（ISO 8601格式） |
| `totalElements` | int | 评论总数 |
| `totalPages` | int | 总页数 |
| `currentPage` | int | 当前页码 |
| `pageSize` | int | 每页数量 |
| `hasNext` | boolean | 是否有下一页 |
| `hasPrevious` | boolean | 是否有上一页 |

### 2. 发表评论

**接口地址**: `POST /api/moments/{momentId}/comments`

**请求参数**:
- `momentId` (路径参数): 动态ID（视频ID）

**请求体**:
```json
{
  "content": "说得对！"
}
```

**请求示例**:
```
POST /api/moments/10/comments
Content-Type: application/json

{
  "content": "说得对！"
}
```

**响应格式**:
```json
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

## 🔧 客户端实现

### 数据模型

#### Comment 模型

```dart
class Comment {
  final int id;
  final int momentId;
  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      momentId: json['momentId'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

#### CommentListResponse 模型

```dart
class CommentListResponse {
  final List<Comment> comments;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    return CommentListResponse(
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}
```

### API Service 实现

```dart
/// 获取视频评论列表
Future<ApiResponse<Map<String, dynamic>>> getVideoComments({
  required int videoId,
  int page = 0,
  int size = 20,
}) async {
  try {
    final response = await _httpManager.get(
      '/api/moments/$videoId/comments',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final comments = data['comments'] as List? ?? [];
      debugPrint('获取评论成功: 总数=${data['totalElements']}, 当前页=${data['currentPage']}, 本页${comments.length}条');
      
      return ApiResponse(
        code: response.code,
        message: response.message,
        data: data,
        success: true,
      );
    }
    
    return ApiResponse(
      code: response.code,
      message: response.message,
      data: null,
      success: false,
    );
  } catch (e) {
    debugPrint('获取视频评论异常: $e');
    rethrow;
  }
}

/// 发表视频评论
Future<ApiResponse<Map<String, dynamic>>> postVideoComment({
  required int videoId,
  required String content,
}) async {
  try {
    final response = await _httpManager.post(
      '/api/moments/$videoId/comments',
      data: {
        'content': content,
      },
    );

    if (response.success) {
      debugPrint('评论发表成功');
    }
    
    return ApiResponse(
      code: response.code,
      message: response.message,
      data: response.data,
      success: response.success,
    );
  } catch (e) {
    debugPrint('发表评论异常: $e');
    rethrow;
  }
}
```

## 📱 功能实现

### 1. 加载评论列表

```dart
Future<void> _loadComments() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final response = await _apiService.getVideoComments(
      videoId: widget.videoId,
      page: 0,
      size: 20,
    );

    if (response.success && response.data != null) {
      final commentResponse = CommentListResponse.fromJson(response.data!);
      
      setState(() {
        _comments = commentResponse.comments;
        _commentCount = commentResponse.totalElements;
        _currentPage = commentResponse.currentPage;
        _hasMore = commentResponse.hasNext;
      });
    }
  } catch (e) {
    debugPrint('加载评论失败: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

### 2. 分页加载更多

```dart
Future<void> _loadMoreComments() async {
  if (_isLoadingMore || !_hasMore) return;

  setState(() {
    _isLoadingMore = true;
  });

  try {
    final nextPage = _currentPage + 1;
    
    final response = await _apiService.getVideoComments(
      videoId: widget.videoId,
      page: nextPage,
      size: 20,
    );

    if (response.success && response.data != null) {
      final commentResponse = CommentListResponse.fromJson(response.data!);
      
      setState(() {
        _comments.addAll(commentResponse.comments);
        _currentPage = commentResponse.currentPage;
        _hasMore = commentResponse.hasNext;
      });
    }
  } finally {
    setState(() {
      _isLoadingMore = false;
    });
  }
}
```

### 3. 滚动监听自动加载

```dart
@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
  _loadComments();
}

void _onScroll() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 200) {
    // 距离底部200px时加载更多
    if (!_isLoadingMore && _hasMore) {
      _loadMoreComments();
    }
  }
}
```

### 4. 发表评论

```dart
Future<void> _postComment() async {
  final content = _commentController.text.trim();
  
  if (content.isEmpty) {
    EasyLoading.showToast('请输入评论内容');
    return;
  }

  setState(() {
    _isPosting = true;
  });

  try {
    final response = await _apiService.postVideoComment(
      videoId: widget.videoId,
      content: content,
    );

    if (response.success && response.data != null) {
      final newComment = Comment.fromJson(response.data!);
      
      setState(() {
        _comments.insert(0, newComment);
        _commentCount++;
        _commentController.clear();
      });
      
      EasyLoading.showSuccess('评论成功');
    }
  } finally {
    setState(() {
      _isPosting = false;
    });
  }
}
```

## 🎯 功能特性

### 1. 首次加载
- ✅ 加载第一页评论（page=0, size=20）
- ✅ 显示评论总数
- ✅ 记录分页信息

### 2. 滚动加载更多
- ✅ 滚动到底部自动加载
- ✅ 防重复加载
- ✅ 显示加载中状态
- ✅ 追加新评论到列表

### 3. 分页状态管理
- ✅ `currentPage`: 当前页码
- ✅ `hasNext`: 是否还有更多
- ✅ `totalElements`: 评论总数
- ✅ `_isLoadingMore`: 加载更多状态

### 4. UI状态
- ✅ 首次加载: 显示loading
- ✅ 加载更多: 底部显示"加载中..."
- ✅ 没有更多: 不显示加载指示器
- ✅ 空状态: 显示友好提示

## 📊 数据流程

### 加载评论流程

```
用户打开评论页面
    ↓
调用 _loadComments()
    ↓
GET /api/moments/{id}/comments?page=0&size=20
    ↓
解析响应数据
    ↓
创建 CommentListResponse 对象
    ↓
更新状态:
  - _comments = 评论列表
  - _commentCount = totalElements
  - _currentPage = 0
  - _hasMore = hasNext
    ↓
渲染UI
```

### 加载更多流程

```
用户滚动到底部（距离200px）
    ↓
触发 _onScroll()
    ↓
检查: !_isLoadingMore && _hasMore
    ↓
调用 _loadMoreComments()
    ↓
GET /api/moments/{id}/comments?page=1&size=20
    ↓
解析响应数据
    ↓
更新状态:
  - _comments.addAll(新评论)
  - _currentPage = 1
  - _hasMore = hasNext
    ↓
渲染新评论
```

### 发表评论流程

```
用户输入评论内容
    ↓
点击发送按钮
    ↓
验证内容非空
    ↓
POST /api/moments/{id}/comments
Body: { "content": "..." }
    ↓
解析响应 → Comment 对象
    ↓
更新状态:
  - _comments.insert(0, newComment)
  - _commentCount++
  - _commentController.clear()
    ↓
渲染新评论（顶部）
    ↓
滚动到顶部
```

## 🧪 测试场景

### 测试1: 首次加载

**步骤**:
```
1. 打开评论页面
2. ✅ 显示loading状态
3. ✅ 加载完成显示评论列表
4. ✅ 标题显示正确的评论总数
5. ✅ 如果totalElements > 20，底部显示"下拉加载更多"
```

**验证**:
- 检查控制台日志: "获取评论成功: 总数=50, 当前页=0, 本页20条"
- 检查UI: 显示20条评论
- 检查状态: `_hasMore = true`

### 测试2: 滚动加载更多

**步骤**:
```
1. 滚动到底部
2. ✅ 底部显示"加载中..."
3. ✅ 加载完成后显示更多评论
4. ✅ 总评论数不变
5. ✅ 继续滚动可以加载更多
```

**验证**:
- 检查控制台日志: "加载更多完成: 当前页=1, 新增20条, 还有更多=true"
- 检查UI: 显示40条评论（20+20）
- 检查状态: `_currentPage = 1`

### 测试3: 加载到最后一页

**步骤**:
```
1. 持续滚动加载
2. ✅ 最后一页加载完成
3. ✅ 底部不再显示"下拉加载更多"
4. ✅ 不再触发加载
```

**验证**:
- 检查控制台日志: "还有更多=false"
- 检查状态: `_hasMore = false`
- 检查UI: 底部没有加载指示器

### 测试4: 发表评论

**步骤**:
```
1. 输入评论内容
2. 点击发送
3. ✅ 按钮显示loading状态
4. ✅ 评论成功后出现在列表顶部
5. ✅ 评论总数+1
6. ✅ 输入框清空
```

**验证**:
- 检查新评论出现在第一位
- 检查标题: 评论数从50变为51
- 检查状态: `_commentCount++`

### 测试5: 空评论列表

**步骤**:
```
1. 打开没有评论的视频
2. ✅ 显示空状态图标和文案
3. ✅ "还没有评论"
4. ✅ "快来发表第一条评论吧~"
```

### 测试6: 网络异常

**步骤**:
```
1. 断开网络
2. 打开评论页面
3. ✅ 显示"加载评论失败"
4. ✅ 可以重试
```

## 🐛 常见问题

### Q1: 评论总数不准确？

**原因**: 发表评论后没有更新 `_commentCount`

**解决**:
```dart
setState(() {
  _comments.insert(0, newComment);
  _commentCount++;  // ✅ 不要忘记这个
});
```

### Q2: 加载更多时重复加载？

**原因**: 没有检查 `_isLoadingMore` 状态

**解决**:
```dart
void _onScroll() {
  if (_isLoadingMore) return;  // ✅ 防重复
  if (!_hasMore) return;       // ✅ 没有更多时不加载
  _loadMoreComments();
}
```

### Q3: 滚动到底部没反应？

**原因**: 
1. 监听器没有添加
2. 距离判断太严格

**解决**:
```dart
// 1. 确保添加监听器
_scrollController.addListener(_onScroll);

// 2. 提前触发（距离底部200px）
if (position.pixels >= position.maxScrollExtent - 200) {
  _loadMoreComments();
}
```

### Q4: 页面关闭后评论数不更新？

**原因**: 没有返回最新评论数

**解决**:
```dart
// 评论页面关闭时
Navigator.pop(context, _commentCount);

// 短视频页面接收
final result = await showModalBottomSheet<int>(...);
if (result != null) {
  setState(() {
    _videos[index] = video.copyWith(commentCount: result);
  });
}
```

## 📝 注意事项

### 1. 分页参数
- `page` 从 **0** 开始，不是从1开始
- `size` 建议设置为20，不要太大

### 2. 时间格式
- 服务器返回 ISO 8601 格式: `"2025-11-20T03:58:42.864Z"`
- 客户端使用 `DateTime.parse()` 解析

### 3. 状态管理
- 使用 `_isLoading` 控制首次加载
- 使用 `_isLoadingMore` 控制加载更多
- 使用 `_hasMore` 判断是否还有数据

### 4. 内存管理
- 评论数量过多时可能占用较多内存
- 建议实现虚拟滚动或限制最大加载数量

## 🎉 总结

### ✅ 已实现功能

- ✅ 完整的分页加载逻辑
- ✅ 滚动自动加载更多
- ✅ 发表评论
- ✅ 评论数实时更新
- ✅ Loading状态管理
- ✅ 空状态处理
- ✅ 错误处理

### 📊 API对接完整度

| 接口 | 状态 | 说明 |
|------|------|------|
| GET /api/moments/{id}/comments | ✅ 完成 | 支持分页参数 |
| POST /api/moments/{id}/comments | ✅ 完成 | 支持发表评论 |
| 分页响应解析 | ✅ 完成 | 完整支持所有字段 |
| 自动加载更多 | ✅ 完成 | 滚动监听 |

---

**更新时间**: 2025-11-20  
**版本**: v2.0  
**状态**: ✅ API对接完成

