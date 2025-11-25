/// API配置类
class ApiConfig {
  // 基础URL配置
  // static const String baseUrl = 'https://niumowangai.top';

  static const String baseUrl = 'http://localhost:8888';
  
  // 连接超时时间（毫秒）
  static const int connectTimeout = 15000;
  
  // 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;
  
  // 发送超时时间（毫秒）
  static const int sendTimeout = 10000;
  
  // ==================== WebSocket 配置 ====================
  // WebSocket地址配置说明：
  // 1. 使用 wss:// 协议（安全的WebSocket）
  // 2. 需要指定正确的端口号
  // 3. 路径会在连接时添加：/ws/chat?token=xxx
  //
  // 常见配置：
  // - 与HTTPS同端口：'wss://niumowangai.top:443'
  // - 独立端口8080：'wss://niumowangai.top:8080'
  // - 无需端口（使用默认）：'wss://niumowangai.top'
  //
  // ⚠️ 请根据后端实际配置修改
  // static const String wsBaseUrl = 'wss://niumowangai.top';
  static const String wsBaseUrl = 'ws://localhost:8888';
  
  
  // API接口路径
  static const String loginPath = '/api/auth/login';
  static const String registerPath = '/api/auth/register';
  static const String logoutPath = '/auth/logout';
  static const String userInfoPath = '/user/info';
  static const String uploadPath = '/upload/file';
  static const String forgotPasswordPath = '/auth/forgot-password';
  static const String resetPasswordPath = '/auth/reset-password';
  
  // 获取当前用户信息
  static const String getUserInfoPath = '/api/auth/me';
  
  // 更新用户信息
  static const String updateUserInfoPath = '/api/auth/profile';
  
  // 文件上传
  static const String uploadSingleFilePath = '/api/files/upload/single';
  
  // 搜索用户（通过用户名）
  static String searchUserPath(String username) => '/api/auth/user/$username';
  
  // 获取用户信息（通过用户ID）
  static String getUserByIdPath(int userId) => '/api/auth/users/$userId';
  
  // 添加好友
  static const String addFriendPath = '/api/friends';
  
  // 获取好友列表
  static const String getFriendsPath = '/api/friends';
  
  // 检查好友关系
  static String checkFriendPath(int userId) => '/api/friends/check/$userId';
  
  // 发送消息
  static const String sendMessagePath = '/api/chat/messages';
  
  // 获取会话列表
  static const String getConversationsPath = '/api/chat/conversations';
  
  // 获取或创建与指定用户的会话
  static String getConversationWithUserPath(int targetUserId) => '/api/chat/conversations/with/$targetUserId';
  
  // 获取历史消息
  static String getMessageHistoryPath(int conversationId) => '/api/chat/messages/$conversationId';
  
  // 标记消息已读
  static String markMessagesAsReadPath(int conversationId) => '/api/chat/messages/$conversationId/read';
  
  // 删除会话
  static String deleteConversationPath(String conversationId) => '/api/chat/conversations/$conversationId';
  
  // 组织架构
  // 获取部门树
  static const String getDepartmentTreePath = '/api/organization/departments/tree';
  
  // 获取所有部门列表（扁平化）
  static const String getAllDepartmentsPath = '/api/organization/departments';
  
  // 获取部门成员列表
  static String getDepartmentMembersPath(int departmentId) => 
      '/api/organization/departments/$departmentId/members';
  
  // 获取当前用户的部门信息
  static const String getMyDepartmentsPath = '/api/organization/my-departments';
  
  // 添加用户到部门
  static const String addUserToDepartmentPath = '/api/organization/departments/members';

  // 工作流
  // 提交请假申请
  static const String submitLeavePath = '/api/workflow/leave';
  
  // 获取待办列表（分页）
  static String getPendingTasksPath({int page = 0, int size = 10}) => 
      '/api/workflow/approval/pending?page=$page&size=$size';
  
  // 获取已办列表（分页）
  static String getDoneTasksPath({int page = 0, int size = 10}) => 
      '/api/workflow/approval/done?page=$page&size=$size';
  
  // 请求头
  static Map<String, dynamic> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
  
  // 是否启用日志
  static const bool enableLog = true;
}

