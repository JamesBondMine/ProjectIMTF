import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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

/// 心跳统计信息
class HeartbeatStats {
  int totalSent = 0;
  int totalReceived = 0;
  final List<int> _latencies = [];
  DateTime? lastPongTime;
  DateTime? lastPingTime;

  /// 丢包率
  double get lossRate =>
      totalSent > 0 ? 1 - (totalReceived / totalSent) : 0;

  /// 平均延迟（毫秒）
  double get avgLatency {
    if (_latencies.isEmpty) return 0;
    return _latencies.reduce((a, b) => a + b) / _latencies.length;
  }

  /// 最大延迟（毫秒）
  int get maxLatency => _latencies.isEmpty ? 0 : _latencies.reduce(max);

  /// 最小延迟（毫秒）
  int get minLatency => _latencies.isEmpty ? 0 : _latencies.reduce(min);

  /// 记录延迟
  void recordLatency(int latencyMs) {
    _latencies.add(latencyMs);
    // 只保留最近100次的记录
    if (_latencies.length > 100) {
      _latencies.removeAt(0);
    }
  }

  /// 连接是否健康
  bool isHealthy() {
    // 最近60秒内收到过pong，且丢包率低于20%
    if (lastPongTime == null) return false;
    final timeSinceLastPong = DateTime.now().difference(lastPongTime!);
    return timeSinceLastPong < const Duration(seconds: 60) && lossRate < 0.2;
  }

  /// 重置统计
  void reset() {
    totalSent = 0;
    totalReceived = 0;
    _latencies.clear();
    lastPongTime = null;
    lastPingTime = null;
  }

  @override
  String toString() {
    return '''
HeartbeatStats{
  发送: $totalSent, 接收: $totalReceived, 丢包率: ${(lossRate * 100).toStringAsFixed(1)}%
  延迟: 平均${avgLatency.toStringAsFixed(0)}ms, 最小${minLatency}ms, 最大${maxLatency}ms
  最后ping: $lastPingTime, 最后pong: $lastPongTime
  健康: ${isHealthy() ? '是' : '否'}
}''';
  }
}

/// WebSocket管理类（增强版）
class WebSocketManagerEnhanced {
  static final WebSocketManagerEnhanced _instance = WebSocketManagerEnhanced._internal();
  factory WebSocketManagerEnhanced() => _instance;

  WebSocket? _webSocket;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _heartbeatTimeoutTimer; // 心跳超时检测定时器
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  final Duration _heartbeatInterval = const Duration(seconds: 30);
  final Duration _heartbeatTimeout = const Duration(seconds: 10); // 心跳超时时间
  bool _enableHeartbeat = true;

  // 心跳统计
  final HeartbeatStats _heartbeatStats = HeartbeatStats();

  // 消息流控制器
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  // 状态流控制器
  final StreamController<WebSocketStatus> _statusController =
      StreamController<WebSocketStatus>.broadcast();

  String? _url;
  Map<String, dynamic>? _headers;

  WebSocketManagerEnhanced._internal();

  /// 获取连接状态
  WebSocketStatus get status => _status;

  /// 获取消息流
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// 获取状态流
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  /// 是否已连接
  bool get isConnected => _status == WebSocketStatus.connected;

  /// 获取心跳统计
  HeartbeatStats get heartbeatStats => _heartbeatStats;

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
    bool enableHeartbeat = true,
  }) async {
    if (_status == WebSocketStatus.connected ||
        _status == WebSocketStatus.connecting) {
      debugPrint('WebSocket已连接或正在连接中');
      return;
    }

    _url = url ?? ApiConfig.wsBaseUrl;
    _headers = headers;
    _enableHeartbeat = enableHeartbeat;

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

      // 重置重连计数和心跳统计
      _reconnectAttempts = 0;
      _heartbeatStats.reset();

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
        debugPrint('✅ 心跳已启用（间隔${_heartbeatInterval.inSeconds}秒，超时${_heartbeatTimeout.inSeconds}秒）');
      } else {
        debugPrint('ℹ️  心跳已禁用');
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
    if (!isConnected) {
      debugPrint('WebSocket未连接，取消发送心跳');
      _stopHeartbeat();
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    sendJson({
      'type': 'ping',
      'timestamp': timestamp,
    });

    _heartbeatStats.totalSent++;
    _heartbeatStats.lastPingTime = DateTime.now();

    // 启动心跳超时检测
    _startHeartbeatTimeout();
  }

  /// 启动心跳超时检测
  void _startHeartbeatTimeout() {
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = Timer(_heartbeatTimeout, () {
      debugPrint('⚠️ 心跳超时！${_heartbeatTimeout.inSeconds}秒内未收到pong响应');
      debugPrint('心跳统计: $_heartbeatStats');
      
      // 心跳超时，认为连接已失效，主动断开并重连
      _onHeartbeatTimeout();
    });
  }

  /// 心跳超时处理
  Future<void> _onHeartbeatTimeout() async {
    debugPrint('触发心跳超时重连机制');
    
    // 先断开当前连接
    await disconnect();
    
    // 触发重连
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      debugPrint('❌ 已达到最大重连次数($_maxReconnectAttempts)，停止重连');
      _updateStatus(WebSocketStatus.error);
    }
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
            _handlePongMessage(jsonData);
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

  /// 处理pong消息
  void _handlePongMessage(Map<String, dynamic> jsonData) {
    // 取消心跳超时检测
    _heartbeatTimeoutTimer?.cancel();
    
    // 更新统计信息
    _heartbeatStats.totalReceived++;
    _heartbeatStats.lastPongTime = DateTime.now();

    // 计算延迟
    if (jsonData.containsKey('timestamp') && _heartbeatStats.lastPingTime != null) {
      try {
        final pingTimestamp = jsonData['timestamp'] as int;
        final pongTimestamp = DateTime.now().millisecondsSinceEpoch;
        final latency = pongTimestamp - pingTimestamp;
        _heartbeatStats.recordLatency(latency);
        debugPrint('✅ 收到心跳响应，延迟: ${latency}ms');
      } catch (e) {
        debugPrint('计算延迟失败: $e');
      }
    } else {
      debugPrint('✅ 收到心跳响应');
    }

    // 输出统计信息（每10次输出一次）
    if (_heartbeatStats.totalReceived % 10 == 0) {
      debugPrint('📊 心跳统计: ${_heartbeatStats}');
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
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ 已达到最大重连次数($_maxReconnectAttempts)，停止重连');
    }
  }

  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        sendHeartbeat();
      } else {
        debugPrint('连接已断开，停止心跳');
        timer.cancel();
      }
    });
    
    // 立即发送一次心跳
    Future.delayed(const Duration(seconds: 1), () {
      if (isConnected) {
        sendHeartbeat();
      }
    });
    
    debugPrint('心跳已启动，间隔${_heartbeatInterval.inSeconds}秒');
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = null;
    debugPrint('心跳已停止');
  }

  /// 计算重连延迟（指数退避）
  Duration _getReconnectDelay() {
    // 指数退避: 1, 2, 4, 8, 16, 32, 60秒
    int delaySeconds = min(1 << _reconnectAttempts, 60);
    return Duration(seconds: delaySeconds);
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }

    _reconnectAttempts++;
    final delay = _getReconnectDelay();
    debugPrint('计划第$_reconnectAttempts次重连（${delay.inSeconds}秒后）...');

    _reconnectTimer = Timer(delay, () {
      if (_status != WebSocketStatus.connected) {
        debugPrint('开始第$_reconnectAttempts次重连');
        connect(
          url: _url,
          headers: _headers,
          autoReconnect: true,
          enableHeartbeat: _enableHeartbeat,
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

  /// 获取连接健康度
  String getHealthStatus() {
    if (!isConnected) {
      return '未连接';
    }
    if (!_enableHeartbeat) {
      return '已连接（心跳禁用）';
    }
    if (_heartbeatStats.isHealthy()) {
      return '健康';
    }
    return '不健康';
  }

  /// 销毁
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}

