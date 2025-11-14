# 后端修复指南

## 🐛 问题描述

### 错误 1：LocalDateTime 序列化失败

```
消息发送失败: Java 8 date/time type `java.time.LocalDateTime` not supported by default: 
add Module "com.fasterxml.jackson.datatype:jackson-datatype-jsr310" to enable handling
```

### 错误 2：心跳包字段冲突（已在前端禁用）

```
Unrecognized field "type" (class org.example.chat.dto.SendMessageRequest), 
not marked as ignorable (3 known properties: "content", "receiverId", "messageType"])
```

---

## ✅ 解决方案

### 方案 1：修复 LocalDateTime 序列化问题（必须）

#### 步骤 1：添加 Jackson JSR310 依赖

**Maven (`pom.xml`)：**

```xml
<dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
    <version>2.15.2</version>
</dependency>
```

**Gradle (`build.gradle`)：**

```gradle
implementation 'com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.2'
```

#### 步骤 2：配置 Jackson ObjectMapper

**Spring Boot 配置类：**

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

@Configuration
public class JacksonConfig {
    
    @Bean
    public ObjectMapper objectMapper() {
        return Jackson2ObjectMapperBuilder.json()
                .modules(new JavaTimeModule())
                .build();
    }
}
```

**或者在 `application.properties/yml` 中配置：**

```yaml
spring:
  jackson:
    serialization:
      write-dates-as-timestamps: false
    deserialization:
      adjust-dates-to-context-time-zone: false
```

#### 步骤 3：在实体类上添加注解（推荐）

```java
import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;

public class MessageResponse {
    private Long id;
    private String content;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
    
    // getters and setters
}
```

---

### 方案 2：支持心跳包（可选，已在前端禁用）

如果需要支持心跳包，有以下几种方式：

#### 方式 1：在 DTO 中忽略未知字段

```java
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class SendMessageRequest {
    private Integer receiverId;
    private String content;
    private String messageType;
    
    // getters and setters
}
```

#### 方式 2：分离心跳和消息处理

```java
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

@Controller
public class WebSocketController {
    
    // 处理聊天消息
    @MessageMapping("/chat/message")
    public void handleMessage(@Payload SendMessageRequest request) {
        // 处理消息
    }
    
    // 处理心跳包
    @MessageMapping("/chat/ping")
    public void handlePing(@Payload Map<String, Object> ping) {
        // 处理心跳
        // 返回 pong
    }
}
```

#### 方式 3：在 WebSocket Handler 中区分消息类型

```java
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

public class ChatWebSocketHandler extends TextWebSocketHandler {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        JsonNode jsonNode = objectMapper.readTree(payload);
        
        // 检查是否是心跳包
        if (jsonNode.has("type") && "ping".equals(jsonNode.get("type").asText())) {
            // 处理心跳
            session.sendMessage(new TextMessage("{\"type\":\"pong\"}"));
            return;
        }
        
        // 处理普通消息
        SendMessageRequest request = objectMapper.treeToValue(jsonNode, SendMessageRequest.class);
        // ... 处理消息逻辑
    }
}
```

---

## 📋 完整示例代码

### 示例 1：Spring Boot WebSocket 配置

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }
    
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/chat")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}
```

### 示例 2：WebSocket 处理器

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Slf4j
@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {
    
    private final ObjectMapper objectMapper;
    
    public ChatWebSocketHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }
    
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        log.info("WebSocket 连接建立: {}", session.getId());
        
        // 从 URL 参数获取 token
        String token = getTokenFromSession(session);
        // 验证 token...
    }
    
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        log.info("收到消息: {}", payload);
        
        try {
            // 解析消息
            var jsonNode = objectMapper.readTree(payload);
            
            // 检查是否是心跳包
            if (jsonNode.has("type") && "ping".equals(jsonNode.get("type").asText())) {
                session.sendMessage(new TextMessage("{\"type\":\"pong\"}"));
                return;
            }
            
            // 解析为消息请求
            SendMessageRequest request = objectMapper.treeToValue(jsonNode, SendMessageRequest.class);
            
            // 处理消息
            MessageResponse response = handleMessage(request);
            
            // 返回响应
            String responseJson = objectMapper.writeValueAsString(response);
            session.sendMessage(new TextMessage(responseJson));
            
        } catch (Exception e) {
            log.error("处理消息失败", e);
            // 发送错误响应
            String errorJson = String.format(
                "{\"type\":\"ERROR\",\"message\":\"消息发送失败: %s\"}", 
                e.getMessage()
            );
            session.sendMessage(new TextMessage(errorJson));
        }
    }
    
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        log.info("WebSocket 连接关闭: {}, status: {}", session.getId(), status);
    }
    
    private String getTokenFromSession(WebSocketSession session) {
        String query = session.getUri().getQuery();
        if (query != null && query.contains("token=")) {
            return query.split("token=")[1].split("&")[0];
        }
        return null;
    }
    
    private MessageResponse handleMessage(SendMessageRequest request) {
        // 实现消息处理逻辑
        MessageResponse response = new MessageResponse();
        response.setId(1L);
        response.setContent(request.getContent());
        response.setCreatedAt(LocalDateTime.now());
        // ... 其他字段
        return response;
    }
}
```

### 示例 3：DTO 定义

```java
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.time.LocalDateTime;

// 消息请求
@Data
@JsonIgnoreProperties(ignoreUnknown = true)  // 忽略未知字段
public class SendMessageRequest {
    private Integer receiverId;
    private String content;
    private String messageType;
}

// 消息响应
@Data
public class MessageResponse {
    private Long id;
    private Integer senderId;
    private Integer receiverId;
    private String content;
    private String messageType;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
}
```

---

## 🧪 测试步骤

### 1. 启动后端服务

```bash
mvn spring-boot:run
# 或
./gradlew bootRun
```

### 2. 测试 WebSocket 连接

使用 wscat 测试：

```bash
# 安装 wscat
npm install -g wscat

# 连接 WebSocket
wscat -c "wss://niumowangai.top/ws/chat?token=YOUR_TOKEN"

# 发送测试消息
{"receiverId":12,"content":"test","messageType":"TEXT"}
```

### 3. 检查日志

后端应该输出：

```
WebSocket 连接建立: xxx
收到消息: {"receiverId":12,"content":"test","messageType":"TEXT"}
消息发送成功
```

而不是：

```
消息发送失败: Java 8 date/time type...
```

---

## 📝 检查清单

### ✅ 必须修复的：

- [ ] 添加 `jackson-datatype-jsr310` 依赖
- [ ] 配置 Jackson ObjectMapper 支持 Java 8 时间类型
- [ ] 在 DTO 中添加 `@JsonFormat` 注解
- [ ] 测试消息发送是否成功

### 🔧 可选优化：

- [ ] 在 DTO 中添加 `@JsonIgnoreProperties(ignoreUnknown = true)`
- [ ] 实现心跳包处理（如果需要）
- [ ] 添加 Token 认证
- [ ] 添加消息日志
- [ ] 实现消息持久化

---

## 🎯 预期效果

### 修复前：

```json
{
  "type": "ERROR",
  "message": "消息发送失败: Java 8 date/time type `java.time.LocalDateTime` not supported..."
}
```

### 修复后：

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

---

## 🔗 参考链接

- [Jackson JSR310 官方文档](https://github.com/FasterXML/jackson-modules-java8)
- [Spring Boot WebSocket 文档](https://spring.io/guides/gs/messaging-stomp-websocket/)
- [Java 8 DateTime API](https://docs.oracle.com/javase/8/docs/api/java/time/package-summary.html)

---

## 💬 需要帮助？

如果修复后仍然有问题，请提供以下信息：

1. **后端框架和版本**
   - Spring Boot 版本
   - Java 版本

2. **依赖配置**
   - `pom.xml` 或 `build.gradle`

3. **完整错误日志**

4. **DTO 类定义**

5. **WebSocket 配置代码**

---

更新时间：2025-11-14

