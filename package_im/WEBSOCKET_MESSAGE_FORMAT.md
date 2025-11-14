# WebSocket 消息格式规范

## 📡 消息格式概览

### Flutter 前端 ➡️ 后端

#### 1. 发送聊天消息

```json
{
  "receiverId": 12,
  "content": "你好",
  "messageType": "TEXT"
}
```

**字段说明：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| receiverId | Integer | ✅ | 接收者用户ID |
| content | String | ✅ | 消息内容 |
| messageType | String | ✅ | 消息类型：TEXT, IMAGE, VIDEO, FILE 等 |

---

### 后端 ➡️ Flutter 前端

#### 1. 消息发送成功

```json
{
  "id": 123,
  "senderId": 11,
  "receiverId": 12,
  "content": "你好",
  "messageType": "TEXT",
  "createdAt": "2025-11-14 12:30:45",
  "updatedAt": "2025-11-14 12:30:45"
}
```

**字段说明：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | Long | ✅ | 消息ID |
| senderId | Integer | ✅ | 发送者用户ID |
| receiverId | Integer | ✅ | 接收者用户ID |
| content | String | ✅ | 消息内容 |
| messageType | String | ✅ | 消息类型 |
| createdAt | String | ✅ | 创建时间（格式：yyyy-MM-dd HH:mm:ss） |
| updatedAt | String | ✅ | 更新时间（格式：yyyy-MM-dd HH:mm:ss） |

#### 2. 错误响应

```json
{
  "type": "ERROR",
  "message": "错误信息描述"
}
```

**字段说明：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | String | ✅ | 固定值：ERROR |
| message | String | ✅ | 错误详情 |

---

## 🔄 完整消息流程

### 场景 1：发送文本消息

```
┌─────────┐                                    ┌─────────┐
│ Flutter │                                    │ Backend │
└────┬────┘                                    └────┬────┘
     │                                              │
     │ 1. 发送消息                                   │
     ├──────────────────────────────────────────────>│
     │ {"receiverId":12,"content":"你好",           │
     │  "messageType":"TEXT"}                       │
     │                                              │
     │                                              │ 2. 验证并保存
     │                                              │
     │ 3. 返回消息详情                               │
     │<──────────────────────────────────────────────┤
     │ {"id":123,"senderId":11,"receiverId":12,    │
     │  "content":"你好","messageType":"TEXT",       │
     │  "createdAt":"2025-11-14 12:30:45"}          │
     │                                              │
```

### 场景 2：发送失败

```
┌─────────┐                                    ┌─────────┐
│ Flutter │                                    │ Backend │
└────┬────┘                                    └────┬────┘
     │                                              │
     │ 1. 发送消息                                   │
     ├──────────────────────────────────────────────>│
     │ {"receiverId":12,"content":"你好",           │
     │  "messageType":"TEXT"}                       │
     │                                              │
     │                                              │ 2. 验证失败
     │                                              │
     │ 3. 返回错误                                   │
     │<──────────────────────────────────────────────┤
     │ {"type":"ERROR",                             │
     │  "message":"接收者不存在"}                     │
     │                                              │
```

---

## 🎯 前端处理逻辑

### 发送消息

```dart
// lib/services/api_service.dart

Future<bool> sendMessageViaWebSocket({
  required int receiverId,
  required String content,
  String messageType = 'TEXT',
}) async {
  if (!_isChatWebSocketConnected) {
    debugPrint('WebSocket 未连接');
    return false;
  }

  final messageData = {
    'receiverId': receiverId,
    'content': content,
    'messageType': messageType,
  };

  _webSocketManager.sendJson(messageData);
  return true;
}
```

### 接收消息

```dart
// lib/services/api_service.dart

void _handleWebSocketMessage(WebSocketMessage wsMessage) {
  if (wsMessage.data is Map<String, dynamic>) {
    final data = wsMessage.data as Map<String, dynamic>;
    
    // 检查是否是错误消息
    if (data['type'] == 'ERROR') {
      debugPrint('❌ WebSocket 错误: ${data['message']}');
      return;
    }
    
    // 检查是否是心跳响应
    if (data['type'] == 'pong') {
      debugPrint('💓 收到心跳响应');
      return;
    }
    
    // 解析为消息
    try {
      final message = Message.fromJson(data);
      _onMessageReceived?.call(message);
      debugPrint('✅ 收到消息: ${message.content}');
    } catch (e) {
      debugPrint('❌ 解析消息失败: $e');
    }
  }
}
```

---

## 🔧 后端处理逻辑

### 接收并处理消息

```java
@Override
protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
    String payload = message.getPayload();
    log.info("收到消息: {}", payload);
    
    try {
        // 解析为消息请求
        SendMessageRequest request = objectMapper.readValue(payload, SendMessageRequest.class);
        
        // 验证
        if (request.getReceiverId() == null) {
            sendError(session, "接收者ID不能为空");
            return;
        }
        
        if (request.getContent() == null || request.getContent().trim().isEmpty()) {
            sendError(session, "消息内容不能为空");
            return;
        }
        
        // 保存消息
        MessageResponse response = messageService.saveMessage(request);
        
        // 返回成功响应
        String responseJson = objectMapper.writeValueAsString(response);
        session.sendMessage(new TextMessage(responseJson));
        
        // 推送给接收者（如果在线）
        WebSocketSession receiverSession = getSession(request.getReceiverId());
        if (receiverSession != null && receiverSession.isOpen()) {
            receiverSession.sendMessage(new TextMessage(responseJson));
        }
        
    } catch (Exception e) {
        log.error("处理消息失败", e);
        sendError(session, "消息处理失败: " + e.getMessage());
    }
}

private void sendError(WebSocketSession session, String errorMessage) throws IOException {
    String errorJson = String.format(
        "{\"type\":\"ERROR\",\"message\":\"%s\"}", 
        errorMessage
    );
    session.sendMessage(new TextMessage(errorJson));
}
```

---

## 📊 消息类型定义

### messageType 枚举值

| 值 | 说明 | 示例 |
|-----|------|------|
| TEXT | 文本消息 | "你好" |
| IMAGE | 图片消息 | "https://example.com/image.jpg" |
| VIDEO | 视频消息 | "https://example.com/video.mp4" |
| AUDIO | 语音消息 | "https://example.com/audio.mp3" |
| FILE | 文件消息 | "https://example.com/file.pdf" |
| LOCATION | 位置消息 | "{"lat":39.9,"lng":116.4}" |
| EMOJI | 表情消息 | "😊" |

---

## ⚠️ 注意事项

### 1. 时间格式

**后端返回格式：**
```json
"createdAt": "2025-11-14 12:30:45"
```

**前端解析：**
```dart
DateTime parseDateTime(String dateTimeStr) {
  // 格式：yyyy-MM-dd HH:mm:ss
  return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeStr);
}
```

### 2. 字段命名

- ✅ 使用 **camelCase**：`receiverId`, `messageType`, `createdAt`
- ❌ 避免 **snake_case**：`receiver_id`, `message_type`, `created_at`

### 3. 必填字段验证

**前端验证：**
```dart
if (content.trim().isEmpty) {
  EasyLoading.showError('消息内容不能为空');
  return;
}

if (receiverId == null || receiverId <= 0) {
  EasyLoading.showError('接收者无效');
  return;
}
```

**后端验证：**
```java
@NotNull(message = "接收者ID不能为空")
private Integer receiverId;

@NotBlank(message = "消息内容不能为空")
private String content;

@NotBlank(message = "消息类型不能为空")
private String messageType;
```

### 4. 错误处理

**统一错误格式：**
```json
{
  "type": "ERROR",
  "message": "具体错误信息"
}
```

**前端错误处理：**
```dart
if (data['type'] == 'ERROR') {
  EasyLoading.showError(data['message'] ?? '未知错误');
  return;
}
```

---

## 🧪 测试用例

### 测试 1：发送文本消息

**输入：**
```json
{
  "receiverId": 12,
  "content": "Hello",
  "messageType": "TEXT"
}
```

**预期输出：**
```json
{
  "id": 123,
  "senderId": 11,
  "receiverId": 12,
  "content": "Hello",
  "messageType": "TEXT",
  "createdAt": "2025-11-14 12:30:45",
  "updatedAt": "2025-11-14 12:30:45"
}
```

### 测试 2：发送图片消息

**输入：**
```json
{
  "receiverId": 12,
  "content": "https://example.com/image.jpg",
  "messageType": "IMAGE"
}
```

**预期输出：**
```json
{
  "id": 124,
  "senderId": 11,
  "receiverId": 12,
  "content": "https://example.com/image.jpg",
  "messageType": "IMAGE",
  "createdAt": "2025-11-14 12:31:00",
  "updatedAt": "2025-11-14 12:31:00"
}
```

### 测试 3：发送空消息（应失败）

**输入：**
```json
{
  "receiverId": 12,
  "content": "",
  "messageType": "TEXT"
}
```

**预期输出：**
```json
{
  "type": "ERROR",
  "message": "消息内容不能为空"
}
```

### 测试 4：接收者不存在（应失败）

**输入：**
```json
{
  "receiverId": 9999,
  "content": "Hello",
  "messageType": "TEXT"
}
```

**预期输出：**
```json
{
  "type": "ERROR",
  "message": "接收者不存在"
}
```

---

## 🔐 认证

### Token 传递方式

WebSocket 连接 URL：
```
wss://niumowangai.top/ws/chat?token=eyJhbGciOiJIUzI1NiJ9...
```

### 后端验证

```java
private String getTokenFromSession(WebSocketSession session) {
    String query = session.getUri().getQuery();
    if (query != null && query.contains("token=")) {
        String token = query.split("token=")[1].split("&")[0];
        // 验证 token
        return token;
    }
    throw new IllegalArgumentException("缺少 token");
}
```

---

## 📝 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| 1.0 | 2025-11-14 | 初始版本 |

---

## 💡 最佳实践

1. **始终验证输入**：前端和后端都要验证
2. **统一错误格式**：使用 `type: "ERROR"` 标识错误
3. **记录日志**：记录所有消息收发
4. **处理断线重连**：保存未发送消息，重连后重发
5. **消息去重**：使用消息ID避免重复
6. **时间戳**：使用统一的时间格式

---

更新时间：2025-11-14

