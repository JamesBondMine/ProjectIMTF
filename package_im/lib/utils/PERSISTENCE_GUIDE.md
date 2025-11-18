# 登录状态持久化使用指南

## ✅ 已完成的功能

成功实现了登录状态持久化，用户登录后即使杀掉进程重新打开应用，也能自动保持登录状态。

## 🏗️ 技术实现

### 1. 本地存储
使用 `shared_preferences` 实现数据持久化：
- **Token** - JWT令牌
- **用户信息** - 完整的用户数据（JSON格式）
- **登录状态** - 布尔值标记

### 2. 核心组件

#### StorageManager（本地存储管理类）
- 单例模式
- 自动初始化
- 提供完整的存储API

#### ApiService（API服务类）
- 登录时自动保存数据
- 启动时自动恢复状态
- 退出时自动清除数据

#### SplashPage（启动页）
- 检查登录状态
- 自动跳转到对应页面

## 📊 数据流程

### 登录流程
```
1. 用户输入账号密码登录
   ↓
2. 调用登录API，获取Token和用户信息
   ↓
3. 保存到内存（ApiService）
   ↓
4. 保存到本地存储（SharedPreferences）
   ↓
5. 跳转到主页
```

### 启动流程
```
1. 应用启动
   ↓
2. 初始化ApiService
   ↓
3. 从本地存储读取Token和用户信息
   ↓
4. 恢复登录状态到内存
   ↓
5. 显示启动页（SplashPage）
   ↓
6. 检查登录状态
   ↓
7. 已登录 → 跳转主页
   未登录 → 跳转登录页
```

### 退出流程
```
1. 用户点击退出登录
   ↓
2. 清除内存中的数据
   ↓
3. 清除本地存储的数据
   ↓
4. 跳转到登录页
```

## 🚀 使用方式

### 1. 自动持久化（无需手动操作）

登录成功后自动保存：
```dart
// 在 login_page.dart 中
final response = await _apiService.login(
  usernameOrEmail: account,
  password: password,
);

// ApiService 会自动保存到本地存储，无需手动操作
```

### 2. 启动时自动恢复

应用启动时自动恢复登录状态：
```dart
// 在 main.dart 中
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化ApiService（自动恢复登录状态）
  await ApiService().init();
  
  runApp(const MyApp());
}
```

### 3. 检查登录状态

```dart
final apiService = ApiService();

// 检查是否已登录
if (apiService.isLoggedIn) {
  print('用户已登录');
  print('用户名: ${apiService.currentUser?.nickname}');
  print('Token: ${apiService.token}');
} else {
  print('用户未登录');
}
```

### 4. 退出登录

```dart
// 退出登录（自动清除所有数据）
await ApiService().logout();
```

## 💾 存储的数据

### 存储键名
- `user_token` - JWT令牌
- `user_info` - 用户信息（JSON字符串）
- `is_logged_in` - 登录状态（布尔值）

### 数据示例

**Token:**
```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOjEwLCJzdWIiOiJzaGFuZ2x1...
```

**用户信息:**
```json
{
  "id": 10,
  "username": "qensahi@163.com",
  "email": "qensahi@163.com",
  "nickname": "shangluo",
  "avatarUrl": null,
  "phone": "5642228124",
  "status": "ACTIVE",
  "userType": "NORMAL",
  "isGuest": false,
  "createdAt": "2025-11-12T11:17:55.792289",
  "updatedAt": "2025-11-12T19:01:03.912872"
}
```

## 🔐 安全性

### 1. 数据加密
- SharedPreferences 的数据存储在应用私有目录
- 其他应用无法访问
- iOS: KeyChain（可选升级）
- Android: EncryptedSharedPreferences（可选升级）

### 2. Token管理
- Token自动添加到所有HTTP请求头
- 退出登录时立即清除
- 应用卸载时自动清除

### 3. 数据验证
- 启动时验证Token是否存在
- 验证用户信息是否完整
- 任何异常都会清除数据并跳转登录页

## 🎯 测试验证

### 测试步骤

1. **登录测试**
   ```
   - 输入账号密码登录
   - 查看控制台日志
   - 确认"数据已保存到本地存储"
   ```

2. **持久化测试**
   ```
   - 登录成功后
   - 完全关闭应用（杀进程）
   - 重新打开应用
   - 应该直接进入主页，无需重新登录
   ```

3. **退出测试**
   ```
   - 点击退出登录
   - 查看控制台日志
   - 确认"退出登录成功，已清除所有数据"
   - 重新打开应用应该显示登录页
   ```

### 查看日志

开启调试后会看到以下日志：

**登录成功时:**
```
ApiService 初始化中...
保存Token: eyJhbGciOiJIUzI1NiJ9...
保存用户信息: {"id":10,"username":"..."}
设置登录状态: true
登录成功: shangluo
数据已保存到本地存储
```

**应用启动时（已登录）:**
```
ApiService 初始化中...
读取登录状态: true
读取Token: eyJhbGciOiJIUzI1NiJ9...
读取用户信息: {id: 10, username: ...}
登录状态恢复成功
Token: eyJhbGciOiJIUzI1NiJ9...
用户: shangluo
```

**退出登录时:**
```
删除Token
删除用户信息
设置登录状态: false
清除所有登录数据
退出登录成功，已清除所有数据
```

## 🛠️ StorageManager API

完整的本地存储API：

```dart
final storage = StorageManager();

// Token管理
await storage.saveToken('token');
String? token = await storage.getToken();
await storage.removeToken();

// 用户信息管理
await storage.saveUserInfo({'id': 1, 'name': 'test'});
Map<String, dynamic>? userInfo = await storage.getUserInfo();
await storage.removeUserInfo();

// 登录状态管理
await storage.setLoggedIn(true);
bool isLoggedIn = await storage.isLoggedIn();

// 清除所有登录数据
await storage.clearLoginData();

// 通用存储方法
await storage.setString('key', 'value');
String? value = await storage.getString('key');
await storage.setInt('key', 123);
await storage.setBool('key', true);
```

## 🔄 应用生命周期

```
启动
  ↓
初始化ApiService
  ↓
从本地存储恢复Token和用户信息
  ↓
显示启动页
  ↓
检查登录状态
  ↓
已登录 → 主页（显示用户信息）
未登录 → 登录页
  ↓
用户操作...
  ↓
退出登录 → 清除所有数据 → 登录页
```

## 📱 跨平台支持

SharedPreferences 支持所有Flutter平台：
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## ⚡ 性能优化

### 1. 异步操作
所有存储操作都是异步的，不会阻塞UI

### 2. 单例模式
StorageManager 和 ApiService 都是单例，避免重复初始化

### 3. 懒加载
SharedPreferences 在第一次使用时才初始化

### 4. 内存缓存
登录状态保存在内存中，读取时不需要每次都访问存储

## 🐛 常见问题

### 1. 登录后杀进程重开还是登录页？
- 检查是否调用了 `ApiService().init()`
- 查看控制台日志，确认数据是否保存成功
- 检查是否有异常导致数据清除

### 2. 数据保存失败？
- 确保在 `main()` 中调用了 `WidgetsFlutterBinding.ensureInitialized()`
- 检查 SharedPreferences 是否初始化成功
- 查看控制台错误日志

### 3. Token失效怎么办？
- 可以在401错误时自动清除登录状态
- 提示用户重新登录
- 可选：实现Token自动刷新机制

## 🚀 未来扩展

### 1. Token自动刷新
```dart
// 在401错误时自动刷新Token
if (response.statusCode == 401) {
  await refreshToken();
  // 重试原请求
}
```

### 2. 数据加密
```dart
// 使用加密存储
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'token', value: token);
```

### 3. 生物识别
```dart
// 使用指纹/Face ID登录
import 'package:local_auth/local_auth.dart';

final auth = LocalAuthentication();
bool authenticated = await auth.authenticate();
```

## 📝 总结

✅ **已实现的功能**
- 登录状态自动持久化
- 应用重启后自动恢复登录
- 退出登录清除所有数据
- 完整的日志记录
- 异常自动处理

✅ **用户体验**
- 登录一次，长期有效
- 无感知的状态恢复
- 启动页平滑过渡
- 安全的退出登录

🎉 **登录状态持久化功能已完全实现，可以正常使用！**

