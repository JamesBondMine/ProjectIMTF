# 网络请求封装文档

## 📦 目录结构

```
lib/network/
  ├── api_config.dart          # API配置
  ├── api_response.dart        # 响应模型
  ├── http_manager.dart        # HTTP请求管理
  ├── websocket_manager.dart   # WebSocket管理
  ├── api_example.dart         # 使用示例
  └── README.md                # 本文档
```

## 🚀 功能特性

### HTTP请求
- ✅ GET请求
- ✅ POST请求
- ✅ PUT请求
- ✅ DELETE请求
- ✅ 单文件上传（带进度）
- ✅ 批量文件上传（带进度）
- ✅ 文件下载（带进度）
- ✅ 请求/响应拦截器
- ✅ Token自动管理
- ✅ 统一错误处理
- ✅ 加载提示集成

### WebSocket
- ✅ 自动连接/重连
- ✅ 心跳保活
- ✅ 文本消息
- ✅ JSON消息
- ✅ 二进制消息
- ✅ 状态监听
- ✅ 消息流监听

## 📝 使用说明

### 1. 配置API基础信息

编辑 `api_config.dart`：

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-api.com';
  static const String wsBaseUrl = 'wss://your-ws.com';
  
  // 修改接口路径
  static const String loginPath = '/auth/login';
  // ...
}
```

### 2. HTTP请求示例

#### GET请求

```dart
import 'package:package_im/network/http_manager.dart';

final httpManager = HttpManager();

// 简单GET请求
final response = await httpManager.get<Map<String, dynamic>>(
  '/api/users',
  queryParameters: {'page': 1, 'size': 10},
  showLoading: true,
  fromJson: (json) => json as Map<String, dynamic>,
);

if (response.success) {
  print('数据: ${response.data}');
}
```

#### POST请求

```dart
// 登录
final response = await httpManager.post<Map<String, dynamic>>(
  '/auth/login',
  data: {
    'account': 'username',
    'password': 'password',
  },
  showLoading: true,
  fromJson: (json) => json as Map<String, dynamic>,
);

if (response.success) {
  String? token = response.data?['token'];
  httpManager.setToken(token!); // 保存Token
}
```

#### 文件上传

```dart
import 'dart:io';

// 单文件上传
File file = File('/path/to/file.jpg');
final response = await httpManager.uploadFile(
  '/upload',
  file,
  fileName: 'avatar.jpg',
  data: {'type': 'avatar'},
  showLoading: true,
  onSendProgress: (sent, total) {
    print('进度: ${(sent / total * 100).toStringAsFixed(2)}%');
  },
);
```

#### DELETE请求

```dart
final response = await httpManager.delete(
  '/api/data/123',
  showLoading: true,
);
```

### 3. WebSocket使用示例

#### 连接WebSocket

```dart
import 'package:package_im/network/websocket_manager.dart';

final wsManager = WebSocketManager();

// 连接
await wsManager.connect(
  url: 'wss://your-ws.com/chat',
  headers: {'Authorization': 'Bearer your_token'},
  autoReconnect: true,
);

// 监听状态
wsManager.statusStream.listen((status) {
  print('WebSocket状态: $status');
});

// 监听消息
wsManager.messageStream.listen((message) {
  print('收到消息: ${message.data}');
});
```

#### 发送消息

```dart
// 发送文本
wsManager.sendText('Hello');

// 发送JSON
wsManager.sendJson({
  'type': 'chat',
  'message': 'Hello, World!',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

#### 断开连接

```dart
await wsManager.disconnect();
```

### 4. Token管理

```dart
// 设置Token
httpManager.setToken('your_token_here');

// 获取Token
String? token = httpManager.getToken();

// 清除Token（退出登录）
httpManager.clearToken();
```

## 🔧 自定义响应模型

创建自定义模型类：

```dart
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

// 使用
final response = await httpManager.get<User>(
  '/api/user/123',
  fromJson: (json) => User.fromJson(json),
);

if (response.success) {
  User user = response.data!;
  print('用户名: ${user.name}');
}
```

## 📊 错误处理

所有请求都自动处理错误，并通过 EasyLoading 显示错误提示：

- 连接超时
- 请求超时
- 网络错误
- HTTP状态码错误（400、401、403、404、500等）

可以通过 try-catch 捕获异常：

```dart
try {
  final response = await httpManager.get('/api/data');
} catch (e) {
  print('请求异常: $e');
}
```

## 🔌 拦截器

HTTP请求自动添加了拦截器：

1. **请求拦截器**：自动添加 Token 到请求头
2. **响应拦截器**：统一处理响应
3. **错误拦截器**：统一错误处理和提示
4. **日志拦截器**：开发环境下打印请求日志

## ⚙️ 高级配置

### 修改超时时间

编辑 `api_config.dart`：

```dart
static const int connectTimeout = 30000; // 30秒
```

### 自定义请求头

```dart
await httpManager.get(
  '/api/data',
  options: Options(
    headers: {
      'Custom-Header': 'value',
    },
  ),
);
```

### WebSocket心跳间隔

修改 `websocket_manager.dart`：

```dart
final Duration _heartbeatInterval = const Duration(seconds: 30);
```

## 📱 完整使用流程

```dart
import 'package:package_im/network/http_manager.dart';
import 'package:package_im/network/websocket_manager.dart';

class ChatService {
  final httpManager = HttpManager();
  final wsManager = WebSocketManager();

  // 1. 登录
  Future<void> login(String account, String password) async {
    final response = await httpManager.post(
      '/auth/login',
      data: {'account': account, 'password': password},
      showLoading: true,
    );
    
    if (response.success) {
      httpManager.setToken(response.data['token']);
      await connectWebSocket();
    }
  }

  // 2. 连接WebSocket
  Future<void> connectWebSocket() async {
    await wsManager.connect(
      url: 'wss://chat.example.com',
      headers: {'Authorization': 'Bearer ${httpManager.getToken()}'},
    );

    wsManager.messageStream.listen((message) {
      // 处理消息
      handleMessage(message.data);
    });
  }

  // 3. 发送消息
  void sendMessage(String text) {
    wsManager.sendJson({
      'type': 'message',
      'content': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // 4. 退出
  Future<void> logout() async {
    await wsManager.disconnect();
    httpManager.clearToken();
  }

  void handleMessage(dynamic data) {
    // 处理接收到的消息
  }
}
```

## 🐛 调试

开启日志：

```dart
// api_config.dart
static const bool enableLog = true;
```

所有请求和响应都会在控制台打印。

## 📦 依赖

- `dio: ^5.9.0` - HTTP客户端
- `flutter_easyloading: ^3.0.5` - 加载提示

## 🎯 最佳实践

1. **单例模式**：HttpManager 和 WebSocketManager 都是单例
2. **Token管理**：登录后立即保存 Token
3. **错误处理**：使用 try-catch 捕获异常
4. **加载提示**：长时间操作设置 showLoading: true
5. **WebSocket重连**：启用自动重连功能
6. **资源释放**：页面销毁时断开 WebSocket 连接

## 📝 注意事项

- 修改 `ApiConfig.baseUrl` 为实际的API地址
- 修改 `ApiConfig.wsBaseUrl` 为实际的WebSocket地址
- 根据后端接口调整响应字段映射
- 生产环境关闭调试日志

---

更多示例请参考 `api_example.dart` 文件。

