/// 聊天会话模型
class ChatConversation {
  final String id;
  final String userId;
  final String targetId; // 对方用户ID
  final String targetName; // 对方名称
  final String? targetAvatarUrl; // 对方头像
  final String lastMessage; // 最后一条消息
  final DateTime lastMessageTime; // 最后消息时间
  final int unreadCount; // 未读消息数
  final String conversationType; // 会话类型：PRIVATE(私聊), GROUP(群聊)
  final bool isPinned; // 是否置顶
  final bool isMuted; // 是否免打扰

  ChatConversation({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetName,
    this.targetAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.conversationType = 'PRIVATE',
    this.isPinned = false,
    this.isMuted = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    // 兼容两种格式：API返回格式 和 本地存储格式
    final otherUserId = json['otherUserId']?.toString() ?? json['targetId']?.toString() ?? '';
    final otherUsername = json['otherUsername'] ?? '';
    final otherNickname = json['otherNickname'] ?? '';
    final displayName = otherNickname.isNotEmpty ? otherNickname : otherUsername;
    
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      targetId: otherUserId,
      targetName: displayName.isNotEmpty ? displayName : (json['targetName'] ?? ''),
      targetAvatarUrl: json['otherAvatarUrl'] ?? json['targetAvatarUrl'],
      lastMessage: json['lastMessageContent'] ?? json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      conversationType: json['conversationType'] ?? 'PRIVATE',
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetId': targetId,
      'targetName': targetName,
      'targetAvatarUrl': targetAvatarUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'conversationType': conversationType,
      'isPinned': isPinned,
      'isMuted': isMuted,
    };
  }

  ChatConversation copyWith({
    String? id,
    String? userId,
    String? targetId,
    String? targetName,
    String? targetAvatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? conversationType,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetAvatarUrl: targetAvatarUrl ?? this.targetAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      conversationType: conversationType ?? this.conversationType,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  String toString() {
    return 'ChatConversation{id: $id, targetName: $targetName, lastMessage: $lastMessage, unreadCount: $unreadCount}';
  }
}

