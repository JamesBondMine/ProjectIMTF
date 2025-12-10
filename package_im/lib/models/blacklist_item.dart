/// 黑名单项模型
class BlacklistItem {
  final int id;
  final int userId;
  final int blockedUserId;
  final String blockedUsername;
  final String blockedNickname;
  final String? blockedAvatarUrl;
  final String? reason;
  final String createdAt;

  BlacklistItem({
    required this.id,
    required this.userId,
    required this.blockedUserId,
    required this.blockedUsername,
    required this.blockedNickname,
    this.blockedAvatarUrl,
    this.reason,
    required this.createdAt,
  });

  factory BlacklistItem.fromJson(Map<String, dynamic> json) {
    return BlacklistItem(
      id: json['id'] as int,
      userId: json['userId'] as int,
      blockedUserId: json['blockedUserId'] as int,
      blockedUsername: json['blockedUsername'] as String,
      blockedNickname: json['blockedNickname'] as String,
      blockedAvatarUrl: json['blockedAvatarUrl'] as String?,
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'blockedUserId': blockedUserId,
      'blockedUsername': blockedUsername,
      'blockedNickname': blockedNickname,
      'blockedAvatarUrl': blockedAvatarUrl,
      'reason': reason,
      'createdAt': createdAt,
    };
  }
}

/// 黑名单列表响应模型
class BlacklistResponse {
  final List<BlacklistItem> blacklist;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  BlacklistResponse({
    required this.blacklist,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory BlacklistResponse.fromJson(Map<String, dynamic> json) {
    return BlacklistResponse(
      blacklist: (json['blacklist'] as List<dynamic>)
          .map((item) => BlacklistItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      pageSize: json['pageSize'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blacklist': blacklist.map((item) => item.toJson()).toList(),
      'totalElements': totalElements,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'pageSize': pageSize,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
    };
  }
}

