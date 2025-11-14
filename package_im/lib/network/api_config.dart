/// API配置类
class ApiConfig {
  // 基础URL配置
  static const String baseUrl = 'https://niumowangai.top';
  
  // 连接超时时间（毫秒）
  static const int connectTimeout = 15000;
  
  // 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;
  
  // 发送超时时间（毫秒）
  static const int sendTimeout = 10000;
  
  // WebSocket地址
  static const String wsBaseUrl = 'wss://niumowangai.top';
  
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
  
  // 添加好友
  static const String addFriendPath = '/api/friends';
  
  // 获取好友列表
  static const String getFriendsPath = '/api/friends';
  
  // 请求头
  static Map<String, dynamic> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
  
  // 是否启用日志
  static const bool enableLog = true;
}

