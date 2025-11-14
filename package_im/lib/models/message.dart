/// 消息模型
class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final int receiverId;
  final String content;
  final String messageType;
  final bool isRead;
  final String createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'TEXT',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  @override
  String toString() {
    return 'Message{id: $id, senderId: $senderId, receiverId: $receiverId, content: $content, messageType: $messageType}';
  }
}

