import 'package:flutter/foundation.dart';
import '../network/http_manager.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';
import '../models/user.dart';
import '../models/login_response.dart';
import '../utils/storage_manager.dart';

/// API服务类
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final HttpManager _httpManager = HttpManager();
  final StorageManager _storageManager = StorageManager();

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

  /// 初始化（从本地存储恢复登录状态）
  Future<void> init() async {
    debugPrint('ApiService 初始化中...');
    await _storageManager.init();
    await _restoreLoginState();
  }

  /// 从本地存储恢复登录状态
  Future<void> _restoreLoginState() async {
    try {
      // 检查是否已登录
      bool isLoggedIn = await _storageManager.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('用户未登录');
        return;
      }

      // 读取Token
      String? token = await _storageManager.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Token为空，清除登录状态');
        await _storageManager.clearLoginData();
        return;
      }

      // 读取用户信息
      Map<String, dynamic>? userInfoJson = await _storageManager.getUserInfo();
      if (userInfoJson == null) {
        debugPrint('用户信息为空，清除登录状态');
        await _storageManager.clearLoginData();
        return;
      }

      // 恢复登录状态
      _token = token;
      _currentUser = User.fromJson(userInfoJson);
      _httpManager.setToken(_token!);

      debugPrint('登录状态恢复成功');
      debugPrint('Token: $_token');
      debugPrint('用户: ${_currentUser?.nickname}');
    } catch (e) {
      debugPrint('恢复登录状态失败: $e');
      await _storageManager.clearLoginData();
    }
  }

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
        // 保存Token和用户信息到内存
        _token = response.data!.token;
        _currentUser = response.data!.user;
        _httpManager.setToken(_token!);

        // 保存到本地存储
        await _storageManager.saveToken(_token!);
        await _storageManager.saveUserInfo(_currentUser!.toJson());
        await _storageManager.setLoggedIn(true);

        debugPrint('登录成功: ${_currentUser?.nickname}');
        debugPrint('Token: $_token');
        debugPrint('数据已保存到本地存储');
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
  /// [nickname] 昵称（可选）
  /// [phone] 手机号（可选）
  Future<ApiResponse<LoginResponseData>> register({
    required String username,
    required String email,
    required String password,
    String? nickname,
    String? phone,
  }) async {
    try {
      debugPrint('开始注册: $email');

      final response = await _httpManager.post<LoginResponseData>(
        ApiConfig.registerPath,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'nickname': nickname ?? '',
          'phone': phone ?? '',
        },
        showLoading: true,
        fromJson: (json) => LoginResponseData.fromJson(json),
      );

      debugPrint('注册响应: $response');

      if (response.success && response.data != null) {
        // 注册成功后自动保存Token和用户信息（相当于自动登录）
        _token = response.data!.token;
        _currentUser = response.data!.user;
        _httpManager.setToken(_token!);

        // 保存到本地存储
        await _storageManager.saveToken(_token!);
        await _storageManager.saveUserInfo(_currentUser!.toJson());
        await _storageManager.setLoggedIn(true);

        debugPrint('注册成功并已自动登录: ${_currentUser?.nickname}');
        debugPrint('Token: $_token');
        debugPrint('数据已保存到本地存储');
      }

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

      // 清除内存中的数据
      _token = null;
      _currentUser = null;
      _httpManager.clearToken();

      // 清除本地存储
      await _storageManager.clearLoginData();

      debugPrint('退出登录成功，已清除所有数据');
    } catch (e) {
      debugPrint('退出登录失败: $e');
      // 即使接口调用失败，也要清除本地数据
      _token = null;
      _currentUser = null;
      _httpManager.clearToken();
      await _storageManager.clearLoginData();
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

