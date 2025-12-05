import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moment.dart';

/// 收藏管理器（本地化存储）
class CollectManager {
  static const String _keyCollectedMoments = 'collected_moments';

  /// 收藏动态
  static Future<bool> collectMoment(Moment moment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已收藏的列表
      final collected = await getCollectedMoments();
      
      // 检查是否已收藏
      if (collected.any((m) => m.id == moment.id)) {
        return false; // 已经收藏过了
      }
      
      // 添加到收藏列表（插入到最前面）
      collected.insert(0, moment);
      
      // 只保留最近500条收藏
      if (collected.length > 500) {
        collected.removeRange(500, collected.length);
      }
      
      // 转换为JSON并保存
      final jsonList = collected.map((m) => m.toJson()).toList();
      await prefs.setString(_keyCollectedMoments, json.encode(jsonList));
      
      return true;
    } catch (e) {
      print('收藏失败: $e');
      return false;
    }
  }

  /// 取消收藏
  static Future<bool> uncollectMoment(int momentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取已收藏的列表
      final collected = await getCollectedMoments();
      
      // 移除指定的动态
      collected.removeWhere((m) => m.id == momentId);
      
      // 保存
      final jsonList = collected.map((m) => m.toJson()).toList();
      await prefs.setString(_keyCollectedMoments, json.encode(jsonList));
      
      return true;
    } catch (e) {
      print('取消收藏失败: $e');
      return false;
    }
  }

  /// 检查是否已收藏
  static Future<bool> isCollected(int momentId) async {
    try {
      final collected = await getCollectedMoments();
      return collected.any((m) => m.id == momentId);
    } catch (e) {
      return false;
    }
  }

  /// 获取所有收藏的动态
  static Future<List<Moment>> getCollectedMoments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCollectedMoments);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((json) => Moment.fromJson(json)).toList();
    } catch (e) {
      print('获取收藏列表失败: $e');
      return [];
    }
  }

  /// 清空所有收藏
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCollectedMoments);
      return true;
    } catch (e) {
      print('清空收藏失败: $e');
      return false;
    }
  }

  /// 获取收藏数量
  static Future<int> getCollectCount() async {
    final collected = await getCollectedMoments();
    return collected.length;
  }
}

