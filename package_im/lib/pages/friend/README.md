# 好友管理功能文档

## 📁 文件结构

```
lib/pages/friend/
  ├── friend_list_page.dart    # 好友列表页面
  ├── add_friend_page.dart     # 添加好友页面
  └── README.md                # 本文档

lib/models/
  └── friend.dart              # 好友数据模型
```

## ✅ 已实现的功能

### 1. 好友列表页面 (FriendListPage)

#### 核心功能
- ✅ **空状态显示** - 没有好友时显示友好的空页面
- ✅ **好友列表** - 按时间倒序排列（最新的在前面）
- ✅ **下拉刷新** - 支持下拉刷新好友列表
- ✅ **添加好友** - 右上角和浮动按钮可添加好友
- ✅ **删除好友** - 左滑删除或菜单删除
- ✅ **设置备注** - 为好友设置备注名
- ✅ **查看详情** - 查看好友详细信息
- ✅ **时间显示** - 智能显示添加时间（刚刚/分钟前/小时前/天前）

#### 页面特性
- 显示好友头像（首字母头像）
- 优先显示备注名，其次昵称，最后用户名
- 三点菜单：详细信息、设置备注、删除好友
- 点击好友项可进入聊天（待开发）

### 2. 添加好友页面 (AddFriendPage)

#### 核心功能
- ✅ **搜索用户** - 通过账号或邮箱搜索
- ✅ **显示搜索结果** - 卡片形式显示用户信息
- ✅ **设置备注** - 添加时可设置备注名
- ✅ **添加好友** - 确认添加并返回列表

#### 页面特性
- 友好的搜索提示
- 美观的用户卡片展示
- 加载状态显示
- 表单验证

### 3. 好友数据模型 (Friend)

#### 字段说明
```dart
class Friend {
  String id;              // 好友关系ID
  String userId;          // 当前用户ID
  String friendId;        // 好友用户ID
  String friendUsername;  // 好友用户名
  String friendNickname;  // 好友昵称
  String? friendAvatarUrl; // 好友头像URL
  String? friendPhone;    // 好友手机号
  String status;          // 状态：PENDING/ACCEPTED/REJECTED
  DateTime createdAt;     // 添加时间
  DateTime? updatedAt;    // 更新时间
  String? remark;         // 备注名
}
```

#### 辅助方法
- `displayName` - 获取显示名称（优先级：备注 > 昵称 > 用户名）
- `copyWith()` - 复制并修改部分字段
- `fromJson()` / `toJson()` - JSON序列化

## 🎨 UI设计

### 空状态页面
- 大图标提示
- 友好的文字说明
- 突出的添加按钮

### 好友列表项
```
┌─────────────────────────────────────┐
│ [头像]  昵称/备注名           [菜单] │
│         账号                        │
│         添加时间                    │
└─────────────────────────────────────┘
```

### 添加好友页面
- 搜索框 + 搜索按钮
- 用户卡片展示
- 备注输入框
- 添加按钮

## 📝 使用示例

### 1. 在主页中集成

```dart
import 'package:package_im/pages/friend/friend_list_page.dart';

// 在底部导航栏中添加
BottomNavigationBarItem(
  icon: Icon(Icons.people),
  label: '好友',
),

// 对应的页面
FriendListPage(),
```

### 2. 直接跳转

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FriendListPage(),
  ),
);
```

## 🔧 待集成API

以下方法需要对接后端API：

### FriendListPage
```dart
// 获取好友列表
Future<void> _loadFriendList() async {
  final response = await ApiService().getFriendList();
  setState(() {
    _friendList = response.data ?? [];
    _sortFriendList();
  });
}

// 删除好友
Future<void> _deleteFriend(Friend friend) async {
  await ApiService().deleteFriend(friend.id);
  setState(() {
    _friendList.remove(friend);
  });
}
```

### AddFriendPage
```dart
// 搜索用户
Future<void> _searchUser() async {
  final response = await ApiService().searchUser(
    _accountController.text.trim()
  );
  setState(() {
    _searchResult = Friend.fromJson(response.data);
  });
}

// 添加好友
Future<void> _addFriend() async {
  final response = await ApiService().addFriend(
    friendId: _searchResult!.friendId,
    remark: _remarkController.text.trim(),
  );
  Navigator.of(context).pop(Friend.fromJson(response.data));
}
```

## 🎯 功能演示

### 场景1：首次打开（无好友）
```
1. 进入好友列表
2. 显示空状态页面
3. 提示"还没有好友"
4. 显示"点击右上角添加好友吧"
5. 可点击添加按钮
```

### 场景2：添加好友
```
1. 点击"添加好友"按钮
2. 进入添加页面
3. 输入账号/邮箱
4. 点击搜索
5. 显示搜索结果
6. 可选填备注名
7. 点击"添加好友"
8. 返回列表，显示新添加的好友
```

### 场景3：管理好友
```
1. 在好友列表中
2. 点击三点菜单
3. 可以：
   - 查看详细信息
   - 设置备注名
   - 删除好友
4. 或左滑直接删除
```

### 场景4：按时间排序
```
1. 好友列表自动按添加时间排序
2. 最新添加的好友在最上面
3. 添加新好友后自动重新排序
```

## 📊 数据流程

### 添加好友流程
```
AddFriendPage → 搜索用户 → 显示结果 → 添加好友
       ↓
返回 Friend 对象
       ↓
FriendListPage 接收 → 添加到列表 → 按时间排序 → 刷新UI
```

### 删除好友流程
```
FriendListPage → 确认删除 → 调用API → 从列表移除 → 刷新UI
```

## 🎨 自定义样式

### 修改主题色
在好友列表中使用了主题色，可以在 `main.dart` 中修改：

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
)
```

### 修改头像样式
在 `_buildFriendItem` 方法中修改 `CircleAvatar`

### 修改列表项高度
修改 `ListTile` 的 `contentPadding`

## 🔍 调试技巧

### 1. 查看好友列表
```dart
print('好友数量: ${_friendList.length}');
_friendList.forEach((friend) => print(friend));
```

### 2. 测试排序功能
```dart
// 手动添加测试数据
final testFriend = Friend(
  id: DateTime.now().toString(),
  userId: '1',
  friendId: '2',
  friendUsername: 'test@example.com',
  friendNickname: '测试好友',
  status: 'ACCEPTED',
  createdAt: DateTime.now(),
);
_friendList.add(testFriend);
_sortFriendList();
```

## 📱 响应式设计

所有页面都支持：
- 不同屏幕尺寸
- 横竖屏切换
- 平板和手机

## 🚀 后续扩展

### 可以添加的功能
1. **分组管理** - 将好友分组（家人、同事、朋友等）
2. **搜索过滤** - 在好友列表中搜索
3. **好友申请** - 显示待处理的好友申请
4. **批量操作** - 批量删除好友
5. **在线状态** - 显示好友在线/离线状态
6. **最近联系** - 按最近聊天时间排序
7. **黑名单** - 拉黑用户功能
8. **好友推荐** - 推荐可能认识的人

## 📞 集成到主页

在 `home_page.dart` 中可以这样集成：

```dart
// 在主页添加好友入口
_buildFeatureCard(
  context,
  icon: Icons.people,
  title: '好友',
  description: '查看和管理好友',
  color: Colors.blue,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FriendListPage(),
      ),
    );
  },
),
```

---

**🎉 好友管理功能已完成，可以直接使用！待后端API开发完成后，只需替换TODO标记的API调用即可。**

