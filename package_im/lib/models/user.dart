/// 用户模型
class User {
  final int id;
  final String username;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String? phone;
  final String status;
  final String userType;
  final bool isGuest;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    this.phone,
    required this.status,
    required this.userType,
    required this.isGuest,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      phone: json['phone'],
      status: json['status'] ?? '',
      userType: json['userType'] ?? '',
      isGuest: json['isGuest'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'status': status,
      'userType': userType,
      'isGuest': isGuest,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, nickname: $nickname}';
  }
}

