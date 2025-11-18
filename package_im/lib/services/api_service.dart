import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/http_manager.dart';
import '../network/api_config.dart';
import '../network/api_response.dart';
import '../network/websocket_manager.dart';
import '../models/user.dart';
import '../models/login_response.dart';
import '../models/message.dart';
import '../models/chat_conversation.dart';
import '../utils/storage_manager.dart';

/// API服务类
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final HttpManager _httpManager = HttpManager();
  final StorageManager _storageManager = StorageManager();
  final WebSocketManager _webSocketManager = WebSocketManager();

  // 当前登录用户
  User? _currentUser;
  String? _token;

  // WebSocket 相关
  bool _isChatWebSocketConnected = false;
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<WebSocketStatus>? _statusSubscription;
  
  // 消息接收回调
  Function(Message)? _onMessageReceived;

  ApiService._internal();

  /// 获取当前用户
  User? get currentUser => _currentUser;

  /// 获取Token
  String? get token => _token;

  /// 是否已登录
  bool get isLoggedIn => _token != null && _currentUser != null;

  /// 是否 WebSocket 已连接
  bool get isChatWebSocketConnected => _isChatWebSocketConnected;

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

  /// Apple 登录
  /// 
  /// [identityToken] Apple 返回的 identityToken
  /// [appleUserId] Apple 用户 ID
  /// [email] Apple 用户邮箱（可选）
  /// [nickname] Apple 用户昵称（可选）
  Future<ApiResponse<LoginResponseData>> appleLogin({
    required String identityToken,
    required String appleUserId,
    String? email,
    String? nickname,
  }) async {
    try {
      debugPrint('开始 Apple 登录');
      debugPrint('appleUserId: $appleUserId');
      debugPrint('email: $email');
      debugPrint('nickname: $nickname');

      final response = await _httpManager.post<LoginResponseData>(
        '/api/auth/apple-login',
        data: {
          'identityToken': identityToken,
          'appleUserId': appleUserId,
          'email': email ?? '',
          'nickname': nickname ?? '',
        },
        showLoading: true,
        fromJson: (json) => LoginResponseData.fromJson(json),
      );

      debugPrint('Apple 登录响应: $response');

      if (response.success && response.data != null) {
        // 保存Token和用户信息到内存
        _token = response.data!.token;
        _currentUser = response.data!.user;
        _httpManager.setToken(_token!);

        // 保存到本地存储
        await _storageManager.saveToken(_token!);
        await _storageManager.saveUserInfo(_currentUser!.toJson());
        await _storageManager.setLoggedIn(true);

        debugPrint('Apple 登录成功: ${_currentUser?.nickname}');
        debugPrint('Token: $_token');
        debugPrint('数据已保存到本地存储');
      }

      return response;
    } catch (e) {
      debugPrint('Apple 登录失败: $e');
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

  /// 获取动态列表
  /// 
  /// [page] 页码（从0开始）
  /// [size] 每页数据量
  Future<ApiResponse<dynamic>> getMoments({
    int page = 0,
    int size = 10,
  }) async {
    try {
      debugPrint('获取动态列表: page=$page, size=$size');

      final response = await _httpManager.get(
        '/api/moments',
        queryParameters: {
          'page': page,
          'size': size,
        },
        showLoading: false,
      );

      debugPrint('动态列表响应: $response');
      return response;
    } catch (e) {
      debugPrint('获取动态列表失败: $e');
      rethrow;
    }
  }

  /// 点赞动态
  /// 
  /// [momentId] 动态ID
  Future<ApiResponse<dynamic>> likeMoment(int momentId) async {
    try {
      debugPrint('点赞动态: momentId=$momentId');

      final response = await _httpManager.post(
        '/api/moments/$momentId/like',
        showLoading: false,
      );

      debugPrint('点赞响应: $response');
      return response;
    } catch (e) {
      debugPrint('点赞失败: $e');
      rethrow;
    }
  }

  /// 取消点赞动态
  /// 
  /// [momentId] 动态ID
  Future<ApiResponse<dynamic>> unlikeMoment(int momentId) async {
    try {
      debugPrint('取消点赞动态: momentId=$momentId');

      final response = await _httpManager.delete(
        '/api/moments/$momentId/like',
        showLoading: false,
      );

      debugPrint('取消点赞响应: $response');
      return response;
    } catch (e) {
      debugPrint('取消点赞失败: $e');
      rethrow;
    }
  }

  /// 发布动态
  /// 
  /// [content] 动态内容
  /// [mediaType] 媒体类型（IMAGE, VIDEO, TEXT等）
  /// [mediaUrls] 媒体文件URL列表
  Future<ApiResponse<dynamic>> publishMoment({
    required String content,
    required String mediaType,
    List<String>? mediaUrls,
  }) async {
    try {
      debugPrint('发布动态: content=$content, mediaType=$mediaType');

      final response = await _httpManager.post(
        '/api/moments',
        data: {
          'content': content,
          'mediaType': mediaType,
          'mediaUrls': mediaUrls ?? [],
        },
        showLoading: true,
      );

      debugPrint('发布动态响应: $response');
      return response;
    } catch (e) {
      debugPrint('发布动态失败: $e');
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

  /// 获取当前用户信息（从服务器）
  Future<ApiResponse<User>> getCurrentUserInfo() async {
    try {
      debugPrint('获取当前用户信息');
      
      final response = await _httpManager.get<User>(
        ApiConfig.getUserInfoPath,
        showLoading: false,
        fromJson: (json) => User.fromJson(json),
      );
      
      if (response.success && response.data != null) {
        // 更新内存中的用户信息
        _currentUser = response.data;
        
        // 保存到本地
        await _storageManager.saveUserInfo(response.data!.toJson());
        
        debugPrint('获取用户信息成功: ${_currentUser!.nickname}');
      }
      
      return response;
    } catch (e) {
      debugPrint('获取用户信息异常: $e');
      rethrow;
    }
  }

  /// 更新用户信息
  Future<ApiResponse<User>> updateUserInfo({
    String? nickname,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      debugPrint('更新用户信息');
      
      // 构建请求参数
      Map<String, dynamic> params = {};
      if (nickname != null) params['nickname'] = nickname;
      if (email != null) params['email'] = email;
      if (phone != null) params['phone'] = phone;
      if (avatarUrl != null) params['avatarUrl'] = avatarUrl;
      
      final response = await _httpManager.put(
        ApiConfig.updateUserInfoPath,
        data: params,
        showLoading: true,
      );
      
      // 根据返回格式解析数据
      if (response.data != null) {
        User updatedUser;
        
        // 检查返回格式，如果有 success 字段，说明是嵌套的格式
        if (response.data is Map && response.data['success'] == true) {
          updatedUser = User.fromJson(response.data['data']);
        } else {
          // 直接是用户数据
          updatedUser = User.fromJson(response.data);
        }
        
        // 更新内存中的用户信息
        _currentUser = updatedUser;
        
        // 保存到本地
        await _storageManager.saveUserInfo(updatedUser.toJson());
        
        debugPrint('更新用户信息成功: ${_currentUser!.nickname}');
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: updatedUser,
          success: true,
        );
      } else {
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: null,
          success: false,
        );
      }
    } catch (e) {
      debugPrint('更新用户信息异常: $e');
      rethrow;
    }
  }

  /// 上传单个文件
  Future<ApiResponse<String>> uploadSingleFile(String filePath) async {
    try {
      debugPrint('上传文件: $filePath');
      
      // 将字符串路径转换为File对象
      final file = File(filePath);
      
      final response = await _httpManager.uploadFile(
        ApiConfig.uploadSingleFilePath,
        file,
        showLoading: true,
      );
      
      if (response.success && response.data != null) {
        // 假设返回的是 { url: "..." } 格式
        String? fileUrl;
        if (response.data is Map) {
          fileUrl = response.data['url']?.toString();
        } else {
          fileUrl = response.data.toString();
        }
        
        debugPrint('文件上传成功: $fileUrl');
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: fileUrl ?? '',
          success: true,
        );
      } else {
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: '',
          success: false,
        );
      }
    } catch (e) {
      debugPrint('文件上传异常: $e');
      rethrow;
    }
  }

  /// 搜索用户（通过用户名或邮箱）
  Future<ApiResponse<User>> searchUser(String username) async {
    try {
      debugPrint('搜索用户: $username');
      
      final response = await _httpManager.get<User>(
        ApiConfig.searchUserPath(username),
        showLoading: true,
        fromJson: (json) {
          // 如果返回格式是 { success: true, data: {...} }
          if (json is Map && json['success'] == true && json['data'] != null) {
            return User.fromJson(json['data']);
          }
          // 否则直接解析
          return User.fromJson(json);
        },
      );
      
      if (response.success && response.data != null) {
        debugPrint('搜索用户成功: ${response.data!.username}, isFriend: ${response.data!.isFriend}');
      }
      
      return response;
    } catch (e) {
      debugPrint('搜索用户异常: $e');
      rethrow;
    }
  }

  /// 获取用户信息（通过用户ID）
  Future<ApiResponse<User>> getUserById(int userId) async {
    try {
      debugPrint('获取用户信息: userId=$userId');
      
      final response = await _httpManager.get<User>(
        ApiConfig.getUserByIdPath(userId),
        showLoading: false,
        fromJson: (json) {
          // 如果返回格式是 { success: true, data: {...} }
          if (json is Map && json['success'] == true && json['data'] != null) {
            return User.fromJson(json['data']);
          }
          // 否则直接解析
          return User.fromJson(json);
        },
      );
      
      if (response.success && response.data != null) {
        debugPrint('获取用户信息成功: ${response.data!.username}');
      }
      
      return response;
    } catch (e) {
      debugPrint('获取用户信息异常: $e');
      rethrow;
    }
  }

  /// 添加好友
  Future<ApiResponse<dynamic>> addFriend({
    required int friendId,
    String? remark,
  }) async {
    try {
      debugPrint('添加好友: friendId=$friendId, remark=$remark');
      
      final response = await _httpManager.post(
        ApiConfig.addFriendPath,
        data: {
          'friendId': friendId,
          if (remark != null && remark.isNotEmpty) 'remark': remark,
        },
        showLoading: true,
      );
      
      if (response.success) {
        debugPrint('添加好友成功');
      }
      
      return response;
    } catch (e) {
      debugPrint('添加好友异常: $e');
      rethrow;
    }
  }

  /// 获取好友列表
  Future<ApiResponse<List<User>>> getFriendList() async {
    try {
      debugPrint('获取好友列表');
      
      final response = await _httpManager.get(
        ApiConfig.getFriendsPath,
        showLoading: false,
      );
      
      if (response.success && response.data != null) {
        List<User> friendList = [];
        
        // 解析好友列表
        // 实际返回格式: { code: 0, msg: "success", data: { friends: [...], totalCount: 1 } }
        if (response.data is Map) {
          if (response.data['friends'] is List) {
            // 格式: data: { friends: [...] }
            friendList = (response.data['friends'] as List)
                .map((item) => User.fromJson(item))
                .toList();
          } else if (response.data['data'] is Map && 
                     response.data['data']['friends'] is List) {
            // 格式: data: { data: { friends: [...] } }
            friendList = (response.data['data']['friends'] as List)
                .map((item) => User.fromJson(item))
                .toList();
          }
        } else if (response.data is List) {
          // 直接是数组格式
          friendList = (response.data as List)
              .map((item) => User.fromJson(item))
              .toList();
        }
        
        debugPrint('获取好友列表成功，共 ${friendList.length} 个好友');
        
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: friendList,
          success: true,
        );
      } else {
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: [],
          success: false,
        );
      }
    } catch (e) {
      debugPrint('获取好友列表异常: $e');
      rethrow;
    }
  }

  /// 发送消息
  Future<ApiResponse<Message>> sendMessage({
    required int receiverId,
    required String content,
    String messageType = 'TEXT',
  }) async {
    try {
      debugPrint('发送消息: receiverId=$receiverId, content=$content, messageType=$messageType');

      final response = await _httpManager.post<Message>(
        ApiConfig.sendMessagePath,
        data: {
          'receiverId': receiverId,
          'content': content,
          'messageType': messageType,
        },
        showLoading: false,
        fromJson: (json) => Message.fromJson(json),
      );

      if (response.success && response.data != null) {
        debugPrint('发送消息成功: ${response.data!.id}');
      }

      return response;
    } catch (e) {
      debugPrint('发送消息异常: $e');
      rethrow;
    }
  }

  /// 获取会话列表
  Future<ApiResponse<List<ChatConversation>>> getConversationList() async {
    try {
      debugPrint('获取会话列表');

      final response = await _httpManager.get(
        ApiConfig.getConversationsPath,
        showLoading: false,
      );

      if (response.success && response.data != null) {
        List<ChatConversation> conversationList = [];

        // 解析会话列表
        // 返回格式: { success: true, data: { conversations: [...], totalCount: 1 } }
        if (response.data is Map) {
          if (response.data['conversations'] is List) {
            // 格式: data: { conversations: [...] }
            conversationList = (response.data['conversations'] as List)
                .map((item) => ChatConversation.fromJson(item))
                .toList();
          } else if (response.data['data'] is Map &&
                     response.data['data']['conversations'] is List) {
            // 格式: data: { data: { conversations: [...] } }
            conversationList = (response.data['data']['conversations'] as List)
                .map((item) => ChatConversation.fromJson(item))
                .toList();
          }
        } else if (response.data is List) {
          // 直接是数组格式
          conversationList = (response.data as List)
              .map((item) => ChatConversation.fromJson(item))
              .toList();
        }

        debugPrint('获取会话列表成功，共 ${conversationList.length} 个会话');

        return ApiResponse(
          code: response.code,
          message: response.message,
          data: conversationList,
          success: true,
        );
      } else {
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: [],
          success: false,
        );
      }
    } catch (e) {
      debugPrint('获取会话列表异常: $e');
      rethrow;
    }
  }

  /// 获取历史消息
  Future<ApiResponse<List<Message>>> getMessageHistory(int conversationId) async {
    try {
      debugPrint('获取历史消息: conversationId=$conversationId');

      final response = await _httpManager.get(
        ApiConfig.getMessageHistoryPath(conversationId),
        showLoading: false,
      );

      if (response.success && response.data != null) {
        List<Message> messageList = [];

        // 解析消息列表
        if (response.data is Map && response.data['messages'] is List) {
          // 格式: { messages: [...], totalCount: 10 }
          messageList = (response.data['messages'] as List)
              .map((item) => Message.fromJson(item))
              .toList();
        } else if (response.data is List) {
          // 直接是数组格式
          messageList = (response.data as List)
              .map((item) => Message.fromJson(item))
              .toList();
        }

        debugPrint('获取历史消息成功，共 ${messageList.length} 条消息');

        return ApiResponse(
          code: response.code,
          message: response.message,
          data: messageList,
          success: true,
        );
      } else {
        return ApiResponse(
          code: response.code,
          message: response.message,
          data: [],
          success: false,
        );
      }
    } catch (e) {
      debugPrint('获取历史消息异常: $e');
      rethrow;
    }
  }

  /// 删除会话
  Future<ApiResponse<dynamic>> deleteConversation(String conversationId) async {
    try {
      debugPrint('删除会话: conversationId=$conversationId');

      final response = await _httpManager.delete(
        ApiConfig.deleteConversationPath(conversationId),
        showLoading: true,
      );

      if (response.success) {
        debugPrint('删除会话成功');
      }

      return response;
    } catch (e) {
      debugPrint('删除会话异常: $e');
      rethrow;
    }
  }

  /// 提交反馈任务到 /api/tasks
  Future<ApiResponse<dynamic>> submitFeedbackTask({
    required String taskType,
    required String taskName,
    required String taskDescription,
    required String featureImagePath,
    String? targetImagePath,
    Map<String, dynamic>? processingParams,
  }) async {
    try {
      debugPrint('提交反馈任务: taskName=$taskName');

      final response = await _httpManager.post(
        '/api/tasks',
        data: {
          'taskType': "BACKGROUND_REMOVAL",
          'taskName': taskName,
          'taskDescription': taskDescription,
          'featureImagePath': featureImagePath,
          'targetImagePath': featureImagePath,
        },
        showLoading: false,
      );

      if (response.success) {
        debugPrint('提交反馈任务成功');
      }

      return response;
    } catch (e) {
      debugPrint('提交反馈任务异常: $e');
      rethrow;
    }
  }

  /// 获取或创建与指定用户的会话
  Future<ApiResponse<ChatConversation>> getConversationWithUser(int targetUserId) async {
    try {
      debugPrint('获取与用户 $targetUserId 的会话...');

      final response = await _httpManager.get(
        ApiConfig.getConversationWithUserPath(targetUserId),
        showLoading: true,
      );

      if (response.success && response.data != null) {
        debugPrint('✅ 获取会话成功');
        debugPrint('会话数据: ${response.data}');

        // 解析会话数据
        final conversationData = response.data as Map<String, dynamic>;
        final conversation = ChatConversation.fromJson(conversationData);

        return ApiResponse(
          success: true,
          code: response.code,
          message: response.message,
          data: conversation,
        );
      } else {
        debugPrint('❌ 获取会话失败: ${response.message}');
        return ApiResponse(
          success: false,
          code: response.code,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      debugPrint('❌ 获取会话异常: $e');
      return ApiResponse(
        success: false,
        code: -1,
        message: '获取会话失败: $e',
        data: null,
      );
    }
  }

  /// 标记会话消息为已读
  Future<ApiResponse<dynamic>> markMessagesAsRead(int conversationId) async {
    try {
      debugPrint('标记会话 $conversationId 的消息为已读...');

      final response = await _httpManager.put(
        ApiConfig.markMessagesAsReadPath(conversationId),
        data: {},
        showLoading: false, // 后台静默调用，不显示加载提示
      );

      if (response.success) {
        debugPrint('✅ 消息已标记为已读');
      } else {
        debugPrint('⚠️ 标记已读失败: ${response.message}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ 标记已读异常: $e');
      return ApiResponse(
        success: false,
        code: -1,
        message: '标记已读失败: $e',
        data: null,
      );
    }
  }

  // ==================== WebSocket 聊天功能 ====================

  /// 连接聊天 WebSocket
  Future<bool> connectChatWebSocket({Function(Message)? onMessageReceived}) async {
    try {
      if (_token == null) {
        debugPrint('未登录，无法连接聊天 WebSocket');
        return false;
      }

      if (_isChatWebSocketConnected) {
        debugPrint('聊天 WebSocket 已连接');
        return true;
      }

      _onMessageReceived = onMessageReceived;

      // 构建 WebSocket URL (使用 wss 协议)
      final wsUrl = '${ApiConfig.wsBaseUrl}/ws/chat?token=$_token';
      
      debugPrint('开始连接聊天 WebSocket: $wsUrl');

      // 监听连接状态
      _statusSubscription = _webSocketManager.statusStream.listen((status) {
        debugPrint('WebSocket 状态变化: $status');
        _isChatWebSocketConnected = (status == WebSocketStatus.connected);
      });

      // 监听消息
      _messageSubscription = _webSocketManager.messageStream.listen((wsMessage) {
        _handleWebSocketMessage(wsMessage);
      });

      // 连接 WebSocket（禁用心跳，避免与后端消息格式冲突）
      await _webSocketManager.connect(
        url: wsUrl,
        autoReconnect: true,
        enableHeartbeat: false,  // 禁用心跳包
      );

      // 等待连接成功（最多5秒）
      int attempts = 0;
      while (!_isChatWebSocketConnected && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (_isChatWebSocketConnected) {
        debugPrint('聊天 WebSocket 连接成功');
        return true;
      } else {
        debugPrint('聊天 WebSocket 连接超时');
        return false;
      }
    } catch (e) {
      debugPrint('连接聊天 WebSocket 失败: $e');
      _isChatWebSocketConnected = false;
      return false;
    }
  }

  /// 断开聊天 WebSocket
  Future<void> disconnectChatWebSocket() async {
    try {
      debugPrint('断开聊天 WebSocket');
      
      await _messageSubscription?.cancel();
      await _statusSubscription?.cancel();
      
      _messageSubscription = null;
      _statusSubscription = null;
      _onMessageReceived = null;
      
      await _webSocketManager.disconnect();
      
      _isChatWebSocketConnected = false;
      
      debugPrint('聊天 WebSocket 已断开');
    } catch (e) {
      debugPrint('断开聊天 WebSocket 异常: $e');
    }
  }

  /// 通过 WebSocket 发送消息
  Future<bool> sendMessageViaWebSocket({
    required int receiverId,
    required String content,
    String messageType = 'TEXT',
  }) async {
    try {
      if (!_isChatWebSocketConnected) {
        debugPrint('WebSocket 未连接，无法发送消息');
        return false;
      }

      final messageData = {
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
      };

      _webSocketManager.sendJson(messageData);
      debugPrint('通过 WebSocket 发送消息: $messageData');
      
      return true;
    } catch (e) {
      debugPrint('WebSocket 发送消息失败: $e');
      return false;
    }
  }

  // 消息监听器列表（支持多个页面同时监听）
  final List<Function(Message)> _messageListeners = [];

  /// 添加消息监听器
  void addMessageListener(Function(Message) listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
      debugPrint('✅ 添加消息监听器，当前监听器数量: ${_messageListeners.length}');
    }
  }

  /// 移除消息监听器
  void removeMessageListener(Function(Message) listener) {
    _messageListeners.remove(listener);
    debugPrint('✅ 移除消息监听器，当前监听器数量: ${_messageListeners.length}');
  }

  /// 处理 WebSocket 接收到的消息
  void _handleWebSocketMessage(WebSocketMessage wsMessage) {
    try {
      if (wsMessage.type == MessageType.text && wsMessage.data is Map) {
        final data = wsMessage.data as Map<String, dynamic>;
        
        debugPrint('收到 WebSocket 消息: $data');
        
        // 检查消息类型
        if (data['type'] == 'NEW_MESSAGE' && data['data'] != null) {
          // 新消息格式：{"type":"NEW_MESSAGE","data":{...}}
          final messageData = data['data'] as Map<String, dynamic>;
          final message = Message.fromJson(messageData);
          
          debugPrint('✅ 解析到新消息: id=${message.id}, content=${message.content}');
          
          // 通知所有监听器
          for (var listener in _messageListeners) {
            try {
              listener(message);
            } catch (e) {
              debugPrint('⚠️ 消息监听器执行失败: $e');
            }
          }
          
          // 兼容旧的单一回调
          if (_onMessageReceived != null) {
            _onMessageReceived!(message);
          }
        } else if (data['type'] == 'ERROR') {
          // 错误消息
          debugPrint('❌ WebSocket 错误: ${data['message']}');
        } else {
          // 尝试直接解析为 Message（兼容旧格式）
          final message = Message.fromJson(data);
          
          // 通知所有监听器
          for (var listener in _messageListeners) {
            try {
              listener(message);
            } catch (e) {
              debugPrint('⚠️ 消息监听器执行失败: $e');
            }
          }
          
          // 兼容旧的单一回调
          if (_onMessageReceived != null) {
            _onMessageReceived!(message);
          }
        }
      }
    } catch (e) {
      debugPrint('处理 WebSocket 消息失败: $e');
    }
  }
}

