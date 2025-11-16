import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 备注管理服务（本地存储）
class RemarkService {
  static const String _remarkKey = 'user_remarks';
  
  // 单例模式
  static final RemarkService _instance = RemarkService._internal();
  factory RemarkService() => _instance;
  RemarkService._internal();
  
  // 备注缓存
  Map<int, String>? _remarkCache;
  
  /// 获取所有备注
  Future<Map<int, String>> _getAllRemarks() async {
    if (_remarkCache != null) {
      return _remarkCache!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final remarksJson = prefs.getString(_remarkKey);
    
    if (remarksJson != null) {
      final Map<String, dynamic> decoded = json.decode(remarksJson);
      _remarkCache = decoded.map((key, value) => MapEntry(int.parse(key), value.toString()));
      return _remarkCache!;
    }
    
    _remarkCache = {};
    return _remarkCache!;
  }
  
  /// 保存所有备注
  Future<void> _saveAllRemarks(Map<int, String> remarks) async {
    final prefs = await SharedPreferences.getInstance();
    final remarksJson = json.encode(remarks.map((key, value) => MapEntry(key.toString(), value)));
    await prefs.setString(_remarkKey, remarksJson);
    _remarkCache = remarks;
  }
  
  /// 获取用户备注
  Future<String?> getRemark(int userId) async {
    final remarks = await _getAllRemarks();
    return remarks[userId];
  }
  
  /// 设置用户备注
  Future<void> setRemark(int userId, String remark) async {
    final remarks = await _getAllRemarks();
    if (remark.trim().isEmpty) {
      remarks.remove(userId);
    } else {
      remarks[userId] = remark.trim();
    }
    await _saveAllRemarks(remarks);
  }
  
  /// 删除用户备注
  Future<void> deleteRemark(int userId) async {
    final remarks = await _getAllRemarks();
    remarks.remove(userId);
    await _saveAllRemarks(remarks);
  }
  
  /// 清除所有备注
  Future<void> clearAllRemarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remarkKey);
    _remarkCache = {};
  }
  
  /// 获取显示名称（优先备注，其次昵称，最后用户名）
  Future<String> getDisplayName({
    required int userId,
    required String nickname,
    required String username,
  }) async {
    final remark = await getRemark(userId);
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    return nickname.isNotEmpty ? nickname : username;
  }
}

