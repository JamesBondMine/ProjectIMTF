import 'package:flutter/foundation.dart';
import '../network/http_manager.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';
import '../models/user.dart';
import '../models/login_response.dart';

/// API服务类
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final HttpManager _httpManager = HttpManager();

  // 当前登录用户
  User? _currentUser;
  String? _token;

  ApiService._internal();

  /// 获取当前用户
  User? get currentUser => _currentUser;

  /// 获取Token
  String? get token => _token;

  /// 是否已登录
  bool get isLoggedIn => _token != null && _currentUser != null;

  /// 用户登录
  /// 
  /// [usernameOrEmail] 用户名或邮箱
  /// [password] 密码
  Future<ApiResponse<LoginResponseData>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      debugPrint('开始登录: $usernameOrEmail');

      final response = await _httpManager.post<LoginResponseData>(
        ApiConfig.loginPath,
        data: {
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        },
        showLoading: true,
        fromJson: (json) => LoginResponseData.fromJson(json),
      );

      debugPrint('登录响应: $response');

      if (response.success && response.data != null) {
        // 保存Token和用户信息
        _token = response.data!.token;
        _currentUser = response.data!.user;
        _httpManager.setToken(_token!);

        debugPrint('登录成功: ${_currentUser?.nickname}');
        debugPrint('Token: $_token');
      }

      return response;
    } catch (e) {
      debugPrint('登录失败: $e');
      rethrow;
    }
  }

  /// 用户注册
  /// 
  /// [username] 用户名
  /// [email] 邮箱
  /// [password] 密码
  Future<ApiResponse<dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('开始注册: $email');

      final response = await _httpManager.post(
        ApiConfig.registerPath,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
        showLoading: true,
      );

      debugPrint('注册响应: $response');

      return response;
    } catch (e) {
      debugPrint('注册失败: $e');
      rethrow;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      // 调用退出登录接口（如果有）
      // await _httpManager.post(ApiConfig.logoutPath);

      // 清除本地数据
      _token = null;
      _currentUser = null;
      _httpManager.clearToken();

      debugPrint('退出登录成功');
    } catch (e) {
      debugPrint('退出登录失败: $e');
      // 即使接口调用失败，也要清除本地数据
      _token = null;
      _currentUser = null;
      _httpManager.clearToken();
    }
  }

  /// 获取用户信息
  Future<ApiResponse<User>> getUserInfo() async {
    try {
      final response = await _httpManager.get<User>(
        ApiConfig.userInfoPath,
        showLoading: false,
        fromJson: (json) => User.fromJson(json),
      );

      if (response.success && response.data != null) {
        _currentUser = response.data;
      }

      return response;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      rethrow;
    }
  }

  /// 忘记密码
  Future<ApiResponse<dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _httpManager.post(
        ApiConfig.forgotPasswordPath,
        data: {'email': email},
        showLoading: true,
      );

      return response;
    } catch (e) {
      debugPrint('忘记密码失败: $e');
      rethrow;
    }
  }

  /// 重置密码
  Future<ApiResponse<dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _httpManager.post(
        ApiConfig.resetPasswordPath,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
        showLoading: true,
      );

      return response;
    } catch (e) {
      debugPrint('重置密码失败: $e');
      rethrow;
    }
  }
}

