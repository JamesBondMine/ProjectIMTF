# WebSocket 配置指南

## 🔍 问题诊断

### 当前遇到的错误
```
WebSocketException: Connection to 'https://niumowangai.top:0/ws/chat?token=xxx' 
was not upgraded to websocket, HTTP status code: 404
```

### 问题分析

#### 1. **端口号问题 `:0`**
- `:0` 是无效端口
- WebSocket 需要指定正确的端口号

#### 2. **协议问题**
- 显示 `https://` 而不是 `wss://`
- 可能是配置错误或系统自动转换

#### 3. **404 错误**
- 后端路径 `/ws/chat` 不存在
- 或者 WebSocket 服务未启动

---

## ⚙️ 配置方案

### 方案 1：使用默认 HTTPS 端口（推荐）

```dart
// lib/network/api_config.dart
static const String wsBaseUrl = 'wss://niumowangai.top';
```

最终连接：`wss://niumowangai.top/ws/chat?token=xxx`

### 方案 2：指定 443 端口

```dart
static const String wsBaseUrl = 'wss://niumowangai.top:443';
```

最终连接：`wss://niumowangai.top:443/ws/chat?token=xxx`

### 方案 3：使用独立 WebSocket 端口

如果后端 WebSocket 在其他端口（如 8080、8081）：

```dart
static const String wsBaseUrl = 'wss://niumowangai.top:8080';
```

最终连接：`wss://niumowangai.top:8080/ws/chat?token=xxx`

---

## 🔧 后端检查清单

### 1. 确认 WebSocket 服务是否运行

```bash
# 测试 WebSocket 连接
wscat -c wss://niumowangai.top/ws/chat

# 或使用 curl 测试
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     https://niumowangai.top/ws/chat
```

### 2. 检查后端配置

**Spring Boot 示例：**
```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/chat")  // 确认路径
                .setAllowedOrigins("*")
                .withSockJS();
    }
}
```

**Node.js 示例：**
```javascript
const wss = new WebSocket.Server({ 
    server: httpsServer,
    path: '/ws/chat'  // 确认路径
});
```

### 3. 确认路径和端口

- **路径**：`/ws/chat` 是否正确？
- **端口**：WebSocket 服务在哪个端口？
- **协议**：是否支持 `wss://`（安全连接）？

---

## 🐛 调试步骤

### 步骤 1：查看连接日志

在 Flutter 控制台查看：
```
flutter: 开始连接聊天 WebSocket: wss://niumowangai.top/ws/chat?token=xxx
flutter: WebSocket状态更新: connecting
flutter: WebSocket连接失败: WebSocketException...
```

### 步骤 2：测试不同配置

#### 测试 1：无端口号
```dart
static const String wsBaseUrl = 'wss://niumowangai.top';
```

#### 测试 2：指定端口 443
```dart
static const String wsBaseUrl = 'wss://niumowangai.top:443';
```

#### 测试 3：尝试其他常见端口
```dart
// 端口 8080
static const String wsBaseUrl = 'wss://niumowangai.top:8080';

// 端口 8081
static const String wsBaseUrl = 'wss://niumowangai.top:8081';

// 端口 9090
static const String wsBaseUrl = 'wss://niumowangai.top:9090';
```

### 步骤 3：检查路径

如果后端路径不是 `/ws/chat`，需要修改 `api_service.dart`：

```dart
// lib/services/api_service.dart (第 809 行附近)

// 当前配置
final wsUrl = '${ApiConfig.wsBaseUrl}/ws/chat?token=$_token';

// 修改为实际路径，例如：
final wsUrl = '${ApiConfig.wsBaseUrl}/websocket?token=$_token';
// 或
final wsUrl = '${ApiConfig.wsBaseUrl}/api/ws?token=$_token';
```

---

## 📋 常见 WebSocket 路径

不同后端框架的常见路径：

| 框架 | 常见路径 |
|------|----------|
| Spring Boot | `/ws/chat` 或 `/websocket` |
| Node.js (Socket.io) | `/socket.io/` |
| Django Channels | `/ws/chat/` |
| FastAPI | `/ws` |
| Express.js | `/ws` 或 `/websocket` |

---

## ✅ 解决方案总结

### 立即可以尝试的：

1. **修改配置文件**（已完成）
   ```dart
   // lib/network/api_config.dart
   static const String wsBaseUrl = 'wss://niumowangai.top';
   ```

2. **重启应用**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **查看新的连接日志**
   - 检查 URL 是否正确
   - 端口号是否合理
   - 是否还有 404 错误

### 需要后端配合的：

1. **确认 WebSocket 服务地址**
   - 请后端开发者提供完整的 WebSocket URL
   - 包括：协议、域名、端口、路径

2. **确认 WebSocket 服务状态**
   - 是否已启动
   - 是否可以正常连接

3. **确认认证方式**
   - Token 是否通过 URL 参数传递？
   - 还是需要通过 Header？

---

## 🔗 推荐配置（按优先级）

### 配置 1：标准 HTTPS 端口（最常见）
```dart
static const String wsBaseUrl = 'wss://niumowangai.top';
// 连接: wss://niumowangai.top/ws/chat?token=xxx
```

### 配置 2：显式指定 443 端口
```dart
static const String wsBaseUrl = 'wss://niumowangai.top:443';
// 连接: wss://niumowangai.top:443/ws/chat?token=xxx
```

### 配置 3：开发环境常用端口
```dart
static const String wsBaseUrl = 'wss://niumowangai.top:8080';
// 连接: wss://niumowangai.top:8080/ws/chat?token=xxx
```

---

## 📞 需要的信息

请向后端开发者询问：

1. **完整的 WebSocket URL 是什么？**
   - 示例：`wss://niumowangai.top:8080/ws/chat`

2. **WebSocket 服务是否已启动？**
   - 可以用浏览器插件或命令行工具测试

3. **Token 如何传递？**
   - URL 参数：`?token=xxx`
   - Header：`Authorization: Bearer xxx`
   - 其他方式？

4. **是否有跨域或防火墙限制？**

---

## 📝 下一步

1. **重新运行应用，查看日志**
2. **如果还是 404，联系后端确认路径**
3. **如果连接超时，检查端口和防火墙**
4. **如果认证失败，检查 Token 传递方式**

---

## 💡 测试工具

推荐使用以下工具测试 WebSocket 连接：

- **在线工具**：https://www.websocket.org/echo.html
- **Chrome 插件**：WebSocket Test Client
- **命令行**：wscat (`npm install -g wscat`)
- **Postman**：支持 WebSocket 测试

---

更新时间：2025-11-14

