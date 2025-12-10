import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 黑名单管理器
/// 用于管理被拉黑的用户列表（本地缓存 + 远程同步）
class BlockManager {
  static final BlockManager _instance = BlockManager._internal();
  factory BlockManager() => _instance;
  BlockManager._internal();

  static const String _blockedUsersKey = 'blocked_users';
  Set<String> _blockedUserIds = {};
  bool _isInitialized = false;

  /// 初始化 - 从本地加载黑名单
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final String? blockedUsersJson = prefs.getString(_blockedUsersKey);
    
    if (blockedUsersJson != null) {
      try {
        final List<dynamic> blockedList = json.decode(blockedUsersJson);
        _blockedUserIds = blockedList.map((e) => e.toString()).toSet();
      } catch (e) {
        _blockedUserIds = {};
      }
    }
    
    _isInitialized = true;
  }

  /// 拉黑用户
  Future<void> blockUser(String userId) async {
    await init();
    _blockedUserIds.add(userId);
    await _saveToLocal();
  }

  /// 解除拉黑
  Future<void> unblockUser(String userId) async {
    await init();
    _blockedUserIds.remove(userId);
    await _saveToLocal();
  }

  /// 检查用户是否被拉黑
  Future<bool> isBlocked(String userId) async {
    await init();
    return _blockedUserIds.contains(userId);
  }

  /// 同步方式检查（需要先初始化）
  bool isBlockedSync(String userId) {
    return _blockedUserIds.contains(userId);
  }

  /// 获取所有被拉黑的用户ID列表
  Future<List<String>> getBlockedUserIds() async {
    await init();
    return _blockedUserIds.toList();
  }

  /// 获取被拉黑用户数量
  Future<int> getBlockedCount() async {
    await init();
    return _blockedUserIds.length;
  }

  /// 批量添加黑名单（从服务器同步）
  Future<void> syncFromServer(List<String> userIds) async {
    await init();
    _blockedUserIds = userIds.toSet();
    await _saveToLocal();
  }

  /// 清空黑名单
  Future<void> clearAll() async {
    await init();
    _blockedUserIds.clear();
    await _saveToLocal();
  }

  /// 保存到本地
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String blockedUsersJson = json.encode(_blockedUserIds.toList());
    await prefs.setString(_blockedUsersKey, blockedUsersJson);
  }

  /// 从服务器刷新黑名单
  Future<void> refreshFromServer(Future<List<String>> Function() fetchFunction) async {
    try {
      final serverBlockedIds = await fetchFunction();
      await syncFromServer(serverBlockedIds);
    } catch (e) {
      // 刷新失败时保持本地数据
      print('刷新黑名单失败: $e');
    }
  }
}

