import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

/// WebSocket连接状态
enum WebSocketStatus {
  connecting, // 连接中
  connected, // 已连接
  disconnected, // 已断开
  error, // 错误
}

/// WebSocket消息类型
enum MessageType {
  text, // 文本消息
  binary, // 二进制消息
  ping, // 心跳包
  pong, // 心跳响应
}

/// WebSocket消息模型
class WebSocketMessage {
  final MessageType type;
  final dynamic data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage{type: $type, data: $data, timestamp: $timestamp}';
  }
}

/// WebSocket管理类
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  WebSocket? _webSocket;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 3);
  final Duration _heartbeatInterval = const Duration(seconds: 30);
  bool _enableHeartbeat = false;  // 保存心跳配置

  // 消息流控制器
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  // 状态流控制器
  final StreamController<WebSocketStatus> _statusController =
      StreamController<WebSocketStatus>.broadcast();

  String? _url;
  Map<String, dynamic>? _headers;

  WebSocketManager._internal();

  /// 获取连接状态
  WebSocketStatus get status => _status;

  /// 获取消息流
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// 获取状态流
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  /// 是否已连接
  bool get isConnected => _status == WebSocketStatus.connected;

  /// 连接WebSocket
  /// 
  /// [url] WebSocket地址，如果为空则使用默认配置
  /// [headers] 请求头
  /// [autoReconnect] 是否自动重连
  /// [enableHeartbeat] 是否启用心跳（默认关闭，因为某些后端不支持）
  Future<void> connect({
    String? url,
    Map<String, dynamic>? headers,
    bool autoReconnect = true,
    bool enableHeartbeat = false,
  }) async {
    if (_status == WebSocketStatus.connected ||
        _status == WebSocketStatus.connecting) {
      debugPrint('WebSocket已连接或正在连接中');
      return;
    }

    _url = url ?? ApiConfig.wsBaseUrl;
    _headers = headers;
    _enableHeartbeat = enableHeartbeat;  // 保存心跳配置用于重连

    try {
      _updateStatus(WebSocketStatus.connecting);
      debugPrint('WebSocket连接中: $_url');

      _webSocket = await WebSocket.connect(
        _url!,
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('WebSocket连接超时');
        },
      );

      _updateStatus(WebSocketStatus.connected);
      debugPrint('WebSocket连接成功');

      // 重置重连计数
      _reconnectAttempts = 0;

      // 监听消息
      _webSocket!.listen(
        _onMessage,
        onError: _onError,
        onDone: () => _onDone(autoReconnect),
        cancelOnError: false,
      );

      // 启动心跳（如果启用）
      if (enableHeartbeat) {
        _startHeartbeat();
        debugPrint('⚠️  心跳已启用，请确保后端支持心跳包');
      } else {
        debugPrint('ℹ️  心跳已禁用（推荐）');
      }
    } catch (e) {
      debugPrint('WebSocket连接失败: $e');
      _updateStatus(WebSocketStatus.error);
      if (autoReconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    debugPrint('主动断开WebSocket连接');
    _stopHeartbeat();
    _stopReconnect();
    await _webSocket?.close();
    _webSocket = null;
    _updateStatus(WebSocketStatus.disconnected);
  }

  /// 发送文本消息
  void sendText(String message) {
    if (!isConnected) {
      debugPrint('WebSocket未连接，无法发送消息');
      return;
    }
    try {
      _webSocket?.add(message);
      debugPrint('发送文本消息: $message');
    } catch (e) {
      debugPrint('发送消息失败: $e');
    }
  }

  /// 发送JSON消息
  void sendJson(Map<String, dynamic> data) {
    if (!isConnected) {
      debugPrint('WebSocket未连接，无法发送消息');
      return;
    }
    try {
      String message = jsonEncode(data);
      _webSocket?.add(message);
      debugPrint('发送JSON消息: $message');
    } catch (e) {
      debugPrint('发送消息失败: $e');
    }
  }

  /// 发送二进制消息
  void sendBinary(List<int> data) {
    if (!isConnected) {
      debugPrint('WebSocket未连接，无法发送消息');
      return;
    }
    try {
      _webSocket?.add(data);
      debugPrint('发送二进制消息，长度: ${data.length}');
    } catch (e) {
      debugPrint('发送消息失败: $e');
    }
  }

  /// 发送心跳包
  void sendHeartbeat() {
    sendJson({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 处理接收到的消息
  void _onMessage(dynamic message) {
    try {
      WebSocketMessage wsMessage;

      if (message is String) {
        // 文本消息
        debugPrint('收到文本消息: $message');
        
        // 尝试解析JSON
        try {
          Map<String, dynamic> jsonData = jsonDecode(message);
          
          // 检查是否是心跳响应
          if (jsonData['type'] == 'pong') {
            wsMessage = WebSocketMessage(
              type: MessageType.pong,
              data: jsonData,
            );
          } else {
            wsMessage = WebSocketMessage(
              type: MessageType.text,
              data: jsonData,
            );
          }
        } catch (_) {
          // 不是JSON，作为普通文本处理
          wsMessage = WebSocketMessage(
            type: MessageType.text,
            data: message,
          );
        }
      } else if (message is List<int>) {
        // 二进制消息
        debugPrint('收到二进制消息，长度: ${message.length}');
        wsMessage = WebSocketMessage(
          type: MessageType.binary,
          data: message,
        );
      } else {
        debugPrint('收到未知类型消息: ${message.runtimeType}');
        return;
      }

      // 通过流发送消息
      _messageController.add(wsMessage);
    } catch (e) {
      debugPrint('处理消息失败: $e');
    }
  }

  /// 处理错误
  void _onError(error) {
    debugPrint('WebSocket错误: $error');
    _updateStatus(WebSocketStatus.error);
  }

  /// 处理连接关闭
  void _onDone(bool autoReconnect) {
    debugPrint('WebSocket连接关闭');
    _updateStatus(WebSocketStatus.disconnected);
    _stopHeartbeat();

    if (autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
    debugPrint('心跳已启动');
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    debugPrint('心跳已停止');
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }

    _reconnectAttempts++;
    debugPrint('计划第$_reconnectAttempts次重连...');

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_status != WebSocketStatus.connected) {
        debugPrint('开始第$_reconnectAttempts次重连');
        connect(
          url: _url,
          headers: _headers,
          autoReconnect: true,
          enableHeartbeat: _enableHeartbeat,  // 使用保存的心跳配置
        );
      }
    });
  }

  /// 停止重连
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    debugPrint('重连已停止');
  }

  /// 更新状态
  void _updateStatus(WebSocketStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
      debugPrint('WebSocket状态更新: $status');
    }
  }

  /// 销毁
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}

