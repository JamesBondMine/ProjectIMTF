import 'user.dart';

/// 登录响应数据模型
class LoginResponseData {
  final String token;
  final String tokenType;
  final User user;

  LoginResponseData({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      token: json['token'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'user': user.toJson(),
    };
  }

  @override
  String toString() {
    return 'LoginResponseData{token: $token, tokenType: $tokenType, user: $user}';
  }
}

