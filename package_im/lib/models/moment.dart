/// 动态模型
class Moment {
  final int id;
  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String content;
  final String mediaType;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final bool liked;
  final bool isFriend;
  final bool isMyMoment; // 是否是我发布的动态
  final bool isFollowing; // 是否已关注该用户
  final DateTime createdAt;
  final DateTime updatedAt;

  Moment({
    required this.id,
    required this.userId,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    required this.content,
    required this.mediaType,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.liked,
    required this.isFriend,
    required this.isMyMoment,
    required this.isFollowing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      content: json['content'] ?? '',
      mediaType: json['mediaType'] ?? 'TEXT',
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      liked: json['liked'] ?? false,
      isFriend: json['isFriend'] ?? false,
      isMyMoment: json['isMyMoment'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'content': content,
      'mediaType': mediaType,
      'mediaUrls': mediaUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'liked': liked,
      'isFriend': isFriend,
      'isMyMoment': isMyMoment,
      'isFollowing': isFollowing,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改某些字段
  Moment copyWith({
    int? id,
    int? userId,
    String? username,
    String? nickname,
    String? avatarUrl,
    String? content,
    String? mediaType,
    List<String>? mediaUrls,
    int? likeCount,
    int? commentCount,
    bool? liked,
    bool? isFriend,
    bool? isMyMoment,
    bool? isFollowing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Moment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      mediaType: mediaType ?? this.mediaType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      liked: liked ?? this.liked,
      isFriend: isFriend ?? this.isFriend,
      isMyMoment: isMyMoment ?? this.isMyMoment,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取相对时间描述（如：刚刚、5分钟前、2小时前等）
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      // 格式化为日期
      return '${createdAt.month}-${createdAt.day}';
    }
  }
}

/// 动态列表响应模型
class MomentListResponse {
  final List<Moment> moments;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  MomentListResponse({
    required this.moments,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory MomentListResponse.fromJson(Map<String, dynamic> json) {
    return MomentListResponse(
      moments: (json['moments'] as List<dynamic>?)
              ?.map((e) => Moment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moments': moments.map((e) => e.toJson()).toList(),
      'totalElements': totalElements,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'pageSize': pageSize,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
    };
  }
}

