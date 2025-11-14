import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 本地存储管理类
class StorageManager {
  static final StorageManager _instance = StorageManager._internal();
  factory StorageManager() => _instance;

  SharedPreferences? _prefs;

  StorageManager._internal();

  // 存储键名
  static const String _keyToken = 'user_token';
  static const String _keyUserInfo = 'user_info';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('StorageManager 初始化完成');
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// 保存Token
  Future<bool> saveToken(String token) async {
    await _ensureInitialized();
    debugPrint('保存Token: $token');
    return await _prefs!.setString(_keyToken, token);
  }

  /// 获取Token
  Future<String?> getToken() async {
    await _ensureInitialized();
    String? token = _prefs!.getString(_keyToken);
    debugPrint('读取Token: $token');
    return token;
  }

  /// 删除Token
  Future<bool> removeToken() async {
    await _ensureInitialized();
    debugPrint('删除Token');
    return await _prefs!.remove(_keyToken);
  }

  /// 保存用户信息（JSON格式）
  Future<bool> saveUserInfo(Map<String, dynamic> userInfo) async {
    await _ensureInitialized();
    String jsonString = jsonEncode(userInfo);
    debugPrint('保存用户信息: $jsonString');
    return await _prefs!.setString(_keyUserInfo, jsonString);
  }

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    await _ensureInitialized();
    String? jsonString = _prefs!.getString(_keyUserInfo);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        Map<String, dynamic> userInfo = jsonDecode(jsonString);
        debugPrint('读取用户信息: $userInfo');
        return userInfo;
      } catch (e) {
        debugPrint('解析用户信息失败: $e');
        return null;
      }
    }
    return null;
  }

  /// 删除用户信息
  Future<bool> removeUserInfo() async {
    await _ensureInitialized();
    debugPrint('删除用户信息');
    return await _prefs!.remove(_keyUserInfo);
  }

  /// 设置登录状态
  Future<bool> setLoggedIn(bool isLoggedIn) async {
    await _ensureInitialized();
    debugPrint('设置登录状态: $isLoggedIn');
    return await _prefs!.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  /// 获取登录状态
  Future<bool> isLoggedIn() async {
    await _ensureInitialized();
    bool isLoggedIn = _prefs!.getBool(_keyIsLoggedIn) ?? false;
    debugPrint('读取登录状态: $isLoggedIn');
    return isLoggedIn;
  }

  /// 清除所有登录相关数据
  Future<void> clearLoginData() async {
    await _ensureInitialized();
    debugPrint('清除所有登录数据');
    await removeToken();
    await removeUserInfo();
    await setLoggedIn(false);
  }

  /// 通用保存方法
  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  /// 通用获取方法
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// 保存int
  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  /// 获取int
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// 保存bool
  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  /// 获取bool
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// 删除指定key
  Future<bool> remove(String key) async {
    await _ensureInitialized();
    return await _prefs!.remove(key);
  }

  /// 清除所有数据
  Future<bool> clearAll() async {
    await _ensureInitialized();
    debugPrint('清除所有本地数据');
    return await _prefs!.clear();
  }

  /// 检查key是否存在
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs!.containsKey(key);
  }
}

