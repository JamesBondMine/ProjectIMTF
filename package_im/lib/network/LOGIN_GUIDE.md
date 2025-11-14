# 登录功能使用指南

## 🎯 已完成的功能

已成功对接真实的登录API，所有功能都已实现并测试通过。

## 📋 API信息

- **接口地址**: `https://niumowangai.top/api/auth/login`
- **请求方式**: POST
- **Content-Type**: application/json

### 请求参数

```json
{
  "usernameOrEmail": "shangluo24244@163.com",
  "password": "Jfy3eew1"
}
```

### 响应示例

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "user": {
      "id": 10,
      "username": "shangluo24244@163.com",
      "email": "shangluo24244@163.com",
      "nickname": "shangluo",
      "avatarUrl": null,
      "phone": "5642228124",
      "status": "ACTIVE",
      "userType": "NORMAL",
      "isGuest": false,
      "createdAt": "2025-11-12T11:17:55.792289",
      "updatedAt": "2025-11-12T19:01:03.912872"
    }
  },
  "timestamp": 1763092363490
}
```

## 🏗️ 项目结构

```
lib/
├── models/                      # 数据模型
│   ├── user.dart               # 用户模型
│   └── login_response.dart     # 登录响应模型
├── services/                    # 业务服务
│   └── api_service.dart        # API服务（单例）
├── network/                     # 网络层
│   ├── api_config.dart         # API配置
│   ├── api_response.dart       # 响应模型
│   ├── http_manager.dart       # HTTP请求管理
│   └── websocket_manager.dart  # WebSocket管理
└── pages/                       # 页面
    ├── login_page.dart         # 登录页面
    ├── register_page.dart      # 注册页面
    ├── forgot_password_page.dart # 忘记密码页面
    └── home_page.dart          # 主页
```

## 🚀 使用说明

### 1. 登录功能

登录页面已完全对接真实API，使用方法：

```dart
import 'package:package_im/services/api_service.dart';

final apiService = ApiService();

// 登录
final response = await apiService.login(
  usernameOrEmail: 'shangluo24244@163.com',
  password: 'Jfy3eew1',
);

if (response.success && response.data != null) {
  // 登录成功
  String token = response.data!.token;
  String nickname = response.data!.user.nickname;
  print('登录成功: $nickname');
  print('Token: $token');
} else {
  // 登录失败
  print('登录失败: ${response.message}');
}
```

### 2. Token管理

ApiService 自动管理 Token：

```dart
// 登录成功后，Token会自动保存
await apiService.login(...);

// 获取当前Token
String? token = apiService.token;

// 检查是否已登录
bool isLoggedIn = apiService.isLoggedIn;

// 获取当前用户信息
User? currentUser = apiService.currentUser;

// 退出登录（清除Token和用户信息）
await apiService.logout();
```

### 3. 测试账号

使用提供的测试账号进行测试：

- **账号**: `shangluo24244@163.com`
- **密码**: `Jfy3eew1`

### 4. 在登录页面中使用

登录页面已经完全集成：

```dart
// lib/pages/login_page.dart

Future<void> _handleLogin() async {
  // 输入验证
  if (_accountController.text.trim().isEmpty) {
    EasyLoading.showError('请输入账号');
    return;
  }

  // 调用API
  final response = await _apiService.login(
    usernameOrEmail: _accountController.text.trim(),
    password: _passwordController.text.trim(),
  );

  // 处理响应
  if (response.success && response.data != null) {
    EasyLoading.showSuccess('登录成功！');
    // 跳转到主页
    Navigator.pushReplacement(...);
  } else {
    EasyLoading.showError(response.message);
  }
}
```

## 📊 数据流转

```
1. 用户输入账号密码
   ↓
2. LoginPage 调用 ApiService.login()
   ↓
3. ApiService 调用 HttpManager.post()
   ↓
4. HttpManager 发送HTTP请求到服务器
   ↓
5. 服务器返回响应数据
   ↓
6. ApiResponse 解析响应
   ↓
7. 保存 Token 到 HttpManager
   ↓
8. 保存用户信息到 ApiService
   ↓
9. 返回登录结果到 LoginPage
   ↓
10. 跳转到 HomePage
```

## 🔐 Token自动管理

所有HTTP请求都会自动携带Token：

```dart
// 登录后，后续所有请求都会自动添加 Authorization 头
// Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...

// 在 http_manager.dart 的请求拦截器中自动处理
void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  if (_token != null && _token!.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $_token';
  }
  handler.next(options);
}
```

## 🎨 UI功能

### 登录页面特性

- ✅ 账号/邮箱输入（支持两种方式）
- ✅ 密码输入（可切换显示/隐藏）
- ✅ 记住我选项
- ✅ 隐私协议勾选（必选）
- ✅ 表单验证
- ✅ 加载状态显示
- ✅ 错误提示
- ✅ 成功提示
- ✅ 忘记密码入口
- ✅ 注册入口

### 主页功能

- ✅ 显示用户昵称
- ✅ 退出登录功能
- ✅ 自动清除Token和用户信息

## ⚡ 错误处理

所有网络请求都有完善的错误处理：

```dart
try {
  final response = await apiService.login(...);
  if (response.success) {
    // 成功处理
  } else {
    // 业务错误
    EasyLoading.showError(response.message);
  }
} catch (e) {
  // 网络异常
  // HttpManager 会自动显示错误提示
  print('登录异常: $e');
}
```

常见错误码：

- `0` - 成功
- `400` - 请求参数错误
- `401` - 未授权（Token无效或过期）
- `403` - 拒绝访问
- `404` - 接口不存在
- `500` - 服务器错误

## 📱 完整登录流程

1. 打开应用 → 显示登录页面
2. 输入账号和密码
3. 勾选隐私协议
4. 点击登录按钮
5. 显示"登录中..."加载提示
6. 请求API
7. 成功：
   - 保存Token
   - 保存用户信息
   - 显示"登录成功！"
   - 跳转到主页
   - 显示用户昵称
8. 失败：
   - 显示错误信息
   - 停留在登录页

## 🔧 调试技巧

### 开启日志

在 `api_config.dart` 中：

```dart
static const bool enableLog = true;
```

### 查看请求日志

所有请求和响应都会在控制台打印：

```
[dio] Request: POST https://niumowangai.top/api/auth/login
[dio] Request Body: {"usernameOrEmail":"...","password":"..."}
[dio] Response: 200 OK
[dio] Response Body: {"code":0,"msg":"success",...}
```

### 查看Token

```dart
print('当前Token: ${ApiService().token}');
print('是否登录: ${ApiService().isLoggedIn}');
print('当前用户: ${ApiService().currentUser}');
```

## 🎯 下一步扩展

可以继续扩展以下功能：

1. **持久化存储**
   - 使用 SharedPreferences 保存Token
   - 应用启动时自动登录

2. **注册功能**
   - 对接注册API
   - 注册成功后自动登录

3. **忘记密码**
   - 对接忘记密码API
   - 邮箱验证码发送

4. **用户信息管理**
   - 个人资料修改
   - 头像上传
   - 密码修改

5. **Token刷新**
   - Token过期自动刷新
   - 401自动跳转登录页

## 📞 技术支持

如果遇到问题：

1. 检查网络连接
2. 查看控制台日志
3. 确认API地址正确
4. 验证请求参数格式

---

**登录功能已完全对接真实API，可以直接使用！** 🎉

