import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// WebSocket 连接测试工具
/// 用于快速测试不同的 WebSocket 配置
class WebSocketTester {
  /// 测试 WebSocket 连接
  /// 
  /// 使用方法：
  /// ```dart
  /// await WebSocketTester.testConnection(
  ///   url: 'wss://niumowangai.top/ws/chat',
  ///   token: 'your_token_here',
  /// );
  /// ```
  static Future<bool> testConnection({
    required String url,
    String? token,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    debugPrint('========================================');
    debugPrint('开始测试 WebSocket 连接');
    debugPrint('URL: $url');
    debugPrint('Token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    debugPrint('========================================');

    String testUrl = url;
    if (token != null && !url.contains('token=')) {
      testUrl = url.contains('?') 
          ? '$url&token=$token' 
          : '$url?token=$token';
    }

    try {
      debugPrint('➡️ 正在连接: $testUrl');
      
      final webSocket = await WebSocket.connect(
        testUrl,
        headers: {
          'User-Agent': 'Flutter WebSocket Tester',
        },
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('连接超时 (${timeout.inSeconds}秒)');
        },
      );

      debugPrint('✅ 连接成功！');
      debugPrint('   协议: ${webSocket.protocol}');
      debugPrint('   状态: ${webSocket.readyState}');

      // 监听消息
      bool receivedMessage = false;
      final subscription = webSocket.listen(
        (message) {
          receivedMessage = true;
          debugPrint('📨 收到消息: $message');
        },
        onError: (error) {
          debugPrint('❌ 接收消息错误: $error');
        },
        onDone: () {
          debugPrint('🔌 连接已关闭');
        },
      );

      // 发送测试消息
      debugPrint('📤 发送测试消息...');
      webSocket.add('{"type":"ping","message":"test"}');

      // 等待响应
      await Future.delayed(const Duration(seconds: 3));

      if (receivedMessage) {
        debugPrint('✅ 成功接收到服务器响应');
      } else {
        debugPrint('⚠️  未收到服务器响应（可能是正常情况）');
      }

      // 关闭连接
      await subscription.cancel();
      await webSocket.close();
      
      debugPrint('========================================');
      debugPrint('测试完成：连接成功 ✅');
      debugPrint('========================================\n');
      
      return true;
    } on SocketException catch (e) {
      debugPrint('❌ Socket 异常: $e');
      debugPrint('   可能原因：');
      debugPrint('   1. 域名无法解析');
      debugPrint('   2. 网络不可达');
      debugPrint('   3. 端口不对或被防火墙拦截');
      return false;
    } on WebSocketException catch (e) {
      debugPrint('❌ WebSocket 异常: $e');
      debugPrint('   可能原因：');
      debugPrint('   1. 路径不正确 (404)');
      debugPrint('   2. 协议升级失败');
      debugPrint('   3. 服务器不支持 WebSocket');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('❌ 超时异常: $e');
      debugPrint('   可能原因：');
      debugPrint('   1. 服务器响应慢');
      debugPrint('   2. 网络不稳定');
      debugPrint('   3. 端口被拦截');
      return false;
    } catch (e) {
      debugPrint('❌ 未知错误: $e');
      return false;
    } finally {
      debugPrint('========================================\n');
    }
  }

  /// 批量测试多个 WebSocket 配置
  /// 
  /// 使用方法：
  /// ```dart
  /// await WebSocketTester.testMultipleConfigs(
  ///   baseUrl: 'niumowangai.top',
  ///   path: '/ws/chat',
  ///   token: 'your_token_here',
  /// );
  /// ```
  static Future<void> testMultipleConfigs({
    required String baseUrl,
    required String path,
    String? token,
  }) async {
    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════════════════╗');
    debugPrint('║     WebSocket 配置批量测试                          ║');
    debugPrint('╚════════════════════════════════════════════════════╝');
    debugPrint('');

    final configs = [
      // 无端口（默认）
      {
        'name': '配置 1：默认端口（推荐）',
        'url': 'wss://$baseUrl$path',
      },
      // 端口 443（HTTPS 标准端口）
      {
        'name': '配置 2：端口 443',
        'url': 'wss://$baseUrl:443$path',
      },
      // 端口 8080（常见开发端口）
      {
        'name': '配置 3：端口 8080',
        'url': 'wss://$baseUrl:8080$path',
      },
      // 端口 8081
      {
        'name': '配置 4：端口 8081',
        'url': 'wss://$baseUrl:8081$path',
      },
      // 端口 9090
      {
        'name': '配置 5：端口 9090',
        'url': 'wss://$baseUrl:9090$path',
      },
    ];

    final results = <String, bool>{};

    for (var config in configs) {
      debugPrint('\n📍 测试 ${config['name']}');
      debugPrint('   URL: ${config['url']}');
      debugPrint('');

      final success = await testConnection(
        url: config['url']!,
        token: token,
        timeout: const Duration(seconds: 5),
      );

      results[config['name']!] = success;

      // 等待一下，避免连接过快
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 输出汇总
    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════════════════╗');
    debugPrint('║     测试结果汇总                                    ║');
    debugPrint('╚════════════════════════════════════════════════════╝');
    debugPrint('');

    bool hasSuccess = false;
    for (var entry in results.entries) {
      final icon = entry.value ? '✅' : '❌';
      debugPrint('$icon ${entry.key}');
      if (entry.value) hasSuccess = true;
    }

    debugPrint('');
    if (hasSuccess) {
      debugPrint('🎉 找到可用的配置！请使用成功的配置更新 api_config.dart');
    } else {
      debugPrint('⚠️  所有配置都失败了，请检查：');
      debugPrint('   1. 后端 WebSocket 服务是否启动');
      debugPrint('   2. 域名和路径是否正确');
      debugPrint('   3. 防火墙是否拦截');
      debugPrint('   4. Token 是否有效');
    }
    debugPrint('');
  }

  /// 测试 Token 认证
  static Future<bool> testWithToken({
    required String url,
    required String token,
  }) async {
    debugPrint('\n');
    debugPrint('╔════════════════════════════════════════════════════╗');
    debugPrint('║     测试 Token 认证                                 ║');
    debugPrint('╚════════════════════════════════════════════════════╝');
    debugPrint('');

    // 测试 1：Token 在 URL 参数中
    debugPrint('🔐 测试 1：Token 作为 URL 参数');
    final test1 = await testConnection(
      url: url,
      token: token,
    );

    await Future.delayed(const Duration(seconds: 1));

    // 测试 2：Token 在 Header 中
    debugPrint('\n🔐 测试 2：Token 在 Header 中');
    try {
      final webSocket = await WebSocket.connect(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'Flutter WebSocket Tester',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('✅ Header 认证成功');
      await webSocket.close();
      return true;
    } catch (e) {
      debugPrint('❌ Header 认证失败: $e');
    }

    return test1;
  }
}

/// 快速测试入口
/// 
/// 在 main.dart 或任何页面调用：
/// ```dart
/// import 'package:package_im/network/websocket_test.dart';
/// 
/// // 单个测试
/// await WebSocketTester.testConnection(
///   url: 'wss://niumowangai.top/ws/chat',
///   token: 'your_token',
/// );
/// 
/// // 批量测试
/// await WebSocketTester.testMultipleConfigs(
///   baseUrl: 'niumowangai.top',
///   path: '/ws/chat',
///   token: 'your_token',
/// );
/// ```

