import 'dart:io';
import 'package:flutter/foundation.dart';
import 'http_manager.dart';
import 'websocket_manager.dart';
import 'api_config.dart';

/// 网络请求使用示例
class ApiExample {
  final HttpManager _httpManager = HttpManager();
  final WebSocketManager _wsManager = WebSocketManager();

  // ============ HTTP请求示例 ============

  /// 示例1: GET请求 - 获取用户信息
  Future<void> getUserInfo() async {
    try {
      final response = await _httpManager.get<Map<String, dynamic>>(
        ApiConfig.userInfoPath,
        queryParameters: {'userId': '123'},
        showLoading: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('用户信息: ${response.data}');
        // 处理数据
      } else {
        debugPrint('请求失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('请求异常: $e');
    }
  }

  /// 示例2: POST请求 - 用户登录
  Future<void> login(String account, String password) async {
    try {
      final response = await _httpManager.post<Map<String, dynamic>>(
        ApiConfig.loginPath,
        data: {
          'account': account,
          'password': password,
        },
        showLoading: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('登录成功: ${response.data}');
        
        // 保存Token
        String? token = response.data?['token'];
        if (token != null) {
          _httpManager.setToken(token);
        }
      } else {
        debugPrint('登录失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('登录异常: $e');
    }
  }

  /// 示例3: POST请求 - 用户注册
  Future<void> register(String account, String email, String password) async {
    try {
      final response = await _httpManager.post<Map<String, dynamic>>(
        ApiConfig.registerPath,
        data: {
          'account': account,
          'email': email,
          'password': password,
        },
        showLoading: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('注册成功: ${response.data}');
      } else {
        debugPrint('注册失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('注册异常: $e');
    }
  }

  /// 示例4: DELETE请求 - 删除数据
  Future<void> deleteData(String id) async {
    try {
      final response = await _httpManager.delete<Map<String, dynamic>>(
        '/api/data/$id',
        showLoading: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('删除成功');
      } else {
        debugPrint('删除失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('删除异常: $e');
    }
  }

  /// 示例5: 单文件上传
  Future<void> uploadSingleFile(File file) async {
    try {
      final response = await _httpManager.uploadFile<Map<String, dynamic>>(
        ApiConfig.uploadPath,
        file,
        fileName: 'avatar.jpg',
        data: {'type': 'avatar'},
        showLoading: true,
        onSendProgress: (sent, total) {
          debugPrint('上传进度: ${(sent / total * 100).toStringAsFixed(2)}%');
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('上传成功: ${response.data}');
        String? fileUrl = response.data?['url'];
        debugPrint('文件地址: $fileUrl');
      } else {
        debugPrint('上传失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('上传异常: $e');
    }
  }

  /// 示例6: 批量文件上传
  Future<void> uploadMultipleFiles(List<File> files) async {
    try {
      final response = await _httpManager.uploadFiles<Map<String, dynamic>>(
        ApiConfig.uploadPath,
        files,
        data: {'type': 'images'},
        showLoading: true,
        onSendProgress: (sent, total) {
          debugPrint('上传进度: ${(sent / total * 100).toStringAsFixed(2)}%');
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('批量上传成功: ${response.data}');
      } else {
        debugPrint('上传失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('上传异常: $e');
    }
  }

  /// 示例7: 文件下载
  Future<void> downloadFile(String url, String savePath) async {
    try {
      await _httpManager.downloadFile(
        url,
        savePath,
        showLoading: true,
        onReceiveProgress: (received, total) {
          debugPrint('下载进度: ${(received / total * 100).toStringAsFixed(2)}%');
        },
      );
      debugPrint('文件下载成功，保存路径: $savePath');
    } catch (e) {
      debugPrint('下载异常: $e');
    }
  }

  // ============ WebSocket请求示例 ============

  /// 示例8: 连接WebSocket
  Future<void> connectWebSocket() async {
    try {
      // 连接WebSocket
      await _wsManager.connect(
        url: '${ApiConfig.wsBaseUrl}/chat',
        headers: {
          'Authorization': 'Bearer ${_httpManager.getToken()}',
        },
        autoReconnect: true,
      );

      // 监听连接状态
      _wsManager.statusStream.listen((status) {
        debugPrint('WebSocket状态变化: $status');
        switch (status) {
          case WebSocketStatus.connecting:
            debugPrint('正在连接...');
            break;
          case WebSocketStatus.connected:
            debugPrint('连接成功');
            break;
          case WebSocketStatus.disconnected:
            debugPrint('连接断开');
            break;
          case WebSocketStatus.error:
            debugPrint('连接错误');
            break;
        }
      });

      // 监听消息
      _wsManager.messageStream.listen((message) {
        debugPrint('收到消息: ${message.type} - ${message.data}');
        
        // 根据消息类型处理
        switch (message.type) {
          case MessageType.text:
            _handleTextMessage(message.data);
            break;
          case MessageType.binary:
            _handleBinaryMessage(message.data);
            break;
          case MessageType.pong:
            debugPrint('收到心跳响应');
            break;
          default:
            break;
        }
      });
    } catch (e) {
      debugPrint('WebSocket连接异常: $e');
    }
  }

  /// 示例9: 发送WebSocket文本消息
  void sendTextMessage(String message) {
    _wsManager.sendText(message);
  }

  /// 示例10: 发送WebSocket JSON消息
  void sendJsonMessage(String type, Map<String, dynamic> content) {
    _wsManager.sendJson({
      'type': type,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 示例11: 发送聊天消息
  void sendChatMessage(String toUserId, String message) {
    _wsManager.sendJson({
      'type': 'chat',
      'toUserId': toUserId,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 示例12: 断开WebSocket连接
  Future<void> disconnectWebSocket() async {
    await _wsManager.disconnect();
  }

  // ============ 辅助方法 ============

  /// 处理文本消息
  void _handleTextMessage(dynamic data) {
    if (data is Map) {
      String? type = data['type'];
      switch (type) {
        case 'chat':
          debugPrint('收到聊天消息: ${data['message']}');
          break;
        case 'notification':
          debugPrint('收到通知: ${data['content']}');
          break;
        default:
          debugPrint('未知消息类型: $type');
      }
    }
  }

  /// 处理二进制消息
  void _handleBinaryMessage(dynamic data) {
    if (data is List<int>) {
      debugPrint('收到二进制数据，长度: ${data.length}');
      // 处理二进制数据
    }
  }

  /// 示例13: 完整的聊天流程
  Future<void> fullChatExample() async {
    // 1. 登录
    await login('testuser', 'password123');

    // 2. 连接WebSocket
    await connectWebSocket();

    // 3. 等待连接成功
    await Future.delayed(const Duration(seconds: 2));

    // 4. 发送消息
    sendChatMessage('user123', 'Hello, World!');

    // 5. 上传图片
    // File imageFile = File('/path/to/image.jpg');
    // await uploadSingleFile(imageFile);

    // 监听消息...

    // 6. 断开连接（用户退出时）
    // await disconnectWebSocket();
  }

  /// 示例14: 设置和清除Token
  void tokenExample() {
    // 设置Token
    _httpManager.setToken('your_token_here');

    // 获取Token
    String? token = _httpManager.getToken();
    debugPrint('当前Token: $token');

    // 清除Token（退出登录时）
    _httpManager.clearToken();
  }
}

