/// 好友模型
class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String friendUsername;
  final String friendNickname;
  final String? friendAvatarUrl;
  final String? friendPhone;
  final String status; // PENDING, ACCEPTED, REJECTED
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? remark; // 备注名

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendUsername,
    required this.friendNickname,
    this.friendAvatarUrl,
    this.friendPhone,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.remark,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      friendId: json['friendId']?.toString() ?? '',
      friendUsername: json['friendUsername'] ?? json['username'] ?? '',
      friendNickname: json['friendNickname'] ?? json['nickname'] ?? '',
      friendAvatarUrl: json['friendAvatarUrl'] ?? json['avatarUrl'],
      friendPhone: json['friendPhone'] ?? json['phone'],
      status: json['status'] ?? 'ACCEPTED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      remark: json['remark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'friendUsername': friendUsername,
      'friendNickname': friendNickname,
      'friendAvatarUrl': friendAvatarUrl,
      'friendPhone': friendPhone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'remark': remark,
    };
  }

  /// 获取显示名称（优先显示备注，然后昵称，最后用户名）
  String get displayName {
    if (remark != null && remark!.isNotEmpty) {
      return remark!;
    }
    if (friendNickname.isNotEmpty) {
      return friendNickname;
    }
    return friendUsername;
  }

  /// 复制并修改部分字段
  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendUsername,
    String? friendNickname,
    String? friendAvatarUrl,
    String? friendPhone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remark,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendUsername: friendUsername ?? this.friendUsername,
      friendNickname: friendNickname ?? this.friendNickname,
      friendAvatarUrl: friendAvatarUrl ?? this.friendAvatarUrl,
      friendPhone: friendPhone ?? this.friendPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remark: remark ?? this.remark,
    );
  }

  @override
  String toString() {
    return 'Friend{id: $id, friendNickname: $friendNickname, status: $status, createdAt: $createdAt}';
  }
}

