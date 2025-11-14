import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  final User friend;
  final int? conversationId; // 会话ID，用于加载历史消息

  const ChatPage({
    super.key,
    required this.friend,
    this.conversationId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 连接 WebSocket
    _connectWebSocket();
    
    // 如果有conversationId，加载历史消息；否则加载模拟数据
    if (widget.conversationId != null) {
      _loadHistoryMessages();
      // 标记消息为已读
      _markMessagesAsRead();
    } else {
      _loadMockMessages();
    }
  }

  @override
  void dispose() {
    // 断开 WebSocket
    _apiService.disconnectChatWebSocket();
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 连接 WebSocket
  Future<void> _connectWebSocket() async {
    try {
      debugPrint('尝试连接聊天 WebSocket...');
      
      final connected = await _apiService.connectChatWebSocket(
        onMessageReceived: _onWebSocketMessage,
      );
      
      if (connected) {
        debugPrint('✅ WebSocket 连接成功，将优先使用 WebSocket 发送消息');
      } else {
        debugPrint('⚠️ WebSocket 连接失败，将使用 HTTP 发送消息');
      }
    } catch (e) {
      debugPrint('❌ WebSocket 连接异常: $e');
    }
  }

  /// 处理 WebSocket 接收到的消息
  void _onWebSocketMessage(Message message) {
    try {
      debugPrint('收到 WebSocket 消息: ${message.toString()}');
      
      // 只处理对方发送的消息（receiverId 是当前用户）
      final currentUserId = _apiService.currentUser?.id;
      if (message.receiverId == currentUserId) {
        final chatMessage = ChatMessage(
          id: message.id.toString(),
          content: message.content,
          isSentByMe: false,
          timestamp: DateTime.parse(message.createdAt),
          messageType: message.messageType,
          imageUrl: message.messageType == 'IMAGE' ? message.content : null,
        );
        
        if (mounted) {
          setState(() {
            _messages.add(chatMessage);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('处理 WebSocket 消息失败: $e');
    }
  }

  /// 标记消息为已读
  Future<void> _markMessagesAsRead() async {
    if (widget.conversationId == null) return;

    try {
      await _apiService.markMessagesAsRead(widget.conversationId!);
      debugPrint('✅ 已标记消息为已读，会话ID: ${widget.conversationId}');
    } catch (e) {
      debugPrint('⚠️ 标记消息已读失败: $e');
      // 不显示错误提示，静默失败
    }
  }

  /// 加载历史消息
  Future<void> _loadHistoryMessages() async {
    if (widget.conversationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getMessageHistory(widget.conversationId!);

      if (response.success && response.data != null) {
        final currentUserId = _apiService.currentUser?.id;
        
        // 转换消息列表
        final messages = response.data!.map((message) {
          return ChatMessage(
            id: message.id.toString(),
            content: message.content,
            isSentByMe: message.senderId == currentUserId,
            timestamp: DateTime.parse(message.createdAt),
            messageType: message.messageType,
            imageUrl: message.messageType == 'IMAGE' ? message.content : null,
          );
        }).toList();

        // 🔑 关键：按时间正序排序（最旧的在前，最新的在后）
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });

        debugPrint('✅ 加载了 ${messages.length} 条历史消息，最旧的在上，最新的在下');

        // 滚动到底部，显示最新消息（等待 ListView 构建完成后再滚动）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottomAfterLoad();
        });
      } else {
        if (response.message.isNotEmpty) {
          EasyLoading.showError(response.message);
        }
      }
    } catch (e) {
      EasyLoading.showError('加载消息失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载模拟消息
  void _loadMockMessages() {
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          content: '你好！',
          isSentByMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: '2',
          content: '你好，很高兴认识你！',
          isSentByMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        ),
        ChatMessage(
          id: '3',
          content: '最近怎么样？',
          isSentByMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          id: '4',
          content: '还不错，你呢？',
          isSentByMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      ]);
    });

    // 加载模拟消息后也滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomAfterLoad();
    });
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 清空输入框
    _messageController.clear();

    // 先添加到本地列表（乐观更新）
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isSentByMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMessage);
    });

    // 滚动到底部
    _scrollToBottom();

    bool success = false;

    try {
      // 1. 优先尝试通过 WebSocket 发送
      if (_apiService.isChatWebSocketConnected) {
        debugPrint('📤 尝试通过 WebSocket 发送消息...');
        success = await _apiService.sendMessageViaWebSocket(
          receiverId: widget.friend.id,
          content: text,
          messageType: 'TEXT',
        );
        
        if (success) {
          debugPrint('✅ WebSocket 发送成功');
          return;
        } else {
          debugPrint('⚠️ WebSocket 发送失败，降级到 HTTP');
        }
      } else {
        debugPrint('⚠️ WebSocket 未连接，使用 HTTP 发送');
      }

      // 2. WebSocket 失败或未连接，使用 HTTP 发送
      final response = await _apiService.sendMessage(
        receiverId: widget.friend.id,
        content: text,
        messageType: 'TEXT',
      );

      if (!response.success) {
        // 发送失败，提示用户
        if (mounted) {
          EasyLoading.showError(response.message.isEmpty ? '发送失败' : response.message);
        }
      } else {
        debugPrint('✅ HTTP 发送成功: ${response.data?.id}');
      }
    } catch (e) {
      // 发送失败，提示用户
      if (mounted) {
        EasyLoading.showError('发送失败: $e');
      }
    }
  }

  /// 滚动到底部（用于新消息）
  void _scrollToBottom({bool animated = true}) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          // 快速跳转到底部（用于首次加载）
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  /// 加载完成后滚动到底部（确保 ListView 已构建）
  void _scrollToBottomAfterLoad({int retryCount = 0}) {
    // 检查是否有消息
    if (_messages.isEmpty) {
      debugPrint('⚠️ 消息列表为空，无需滚动');
      return;
    }

    if (!_scrollController.hasClients) {
      // 如果 ScrollController 还没有 clients，延迟后重试（最多重试5次）
      if (retryCount >= 5) {
        debugPrint('⚠️ 滚动重试次数过多，放弃');
        return;
      }
      
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottomAfterLoad(retryCount: retryCount + 1);
      });
      return;
    }

    _performScroll();
  }

  /// 执行滚动操作
  void _performScroll() {
    try {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        // 等待一帧，确保 ListView 完全构建
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final maxScrollExtent = _scrollController.position.maxScrollExtent;
            if (maxScrollExtent > 0) {
              _scrollController.jumpTo(maxScrollExtent);
              debugPrint('✅ 已滚动到底部显示最新消息 (滚动距离: $maxScrollExtent)');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ 滚动到底部失败: $e');
    }
  }

  /// 选择并发送图片
  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      // 1. 选择图片
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // 显示加载提示
      EasyLoading.show(status: '发送中...');

      // 2. 上传图片获取URL
      final uploadResult = await _apiService.uploadSingleFile(image.path);

      if (!uploadResult.success || uploadResult.data == null) {
        EasyLoading.showError('图片上传失败');
        return;
      }

      String imageUrl = uploadResult.data!;

      // 3. 先添加到本地列表（乐观更新）
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '[图片]',
        isSentByMe: true,
        timestamp: DateTime.now(),
        messageType: 'IMAGE',
        imageUrl: imageUrl,
      );

      setState(() {
        _messages.add(tempMessage);
      });

      // 滚动到底部
      _scrollToBottom();

      // 4. 发送图片消息
      bool success = false;

      // 优先尝试通过 WebSocket 发送
      if (_apiService.isChatWebSocketConnected) {
        debugPrint('📤 尝试通过 WebSocket 发送图片...');
        success = await _apiService.sendMessageViaWebSocket(
          receiverId: widget.friend.id,
          content: imageUrl,
          messageType: 'IMAGE',
        );
        
        if (success) {
          debugPrint('✅ WebSocket 发送图片成功');
          EasyLoading.dismiss();
          return;
        } else {
          debugPrint('⚠️ WebSocket 发送图片失败，降级到 HTTP');
        }
      } else {
        debugPrint('⚠️ WebSocket 未连接，使用 HTTP 发送图片');
      }

      // WebSocket 失败或未连接，使用 HTTP 发送
      final response = await _apiService.sendMessage(
        receiverId: widget.friend.id,
        content: imageUrl, // 图片消息的content是图片URL
        messageType: 'IMAGE',
      );

      EasyLoading.dismiss();

      if (!response.success) {
        if (mounted) {
          EasyLoading.showError(response.message.isEmpty ? '发送失败' : response.message);
        }
      } else {
        debugPrint('✅ HTTP 发送图片成功: ${response.data?.id}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        EasyLoading.showError('发送失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        titleSpacing: 0,
        title: Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: widget.friend.avatarUrl != null
                  ? NetworkImage(widget.friend.avatarUrl!)
                  : null,
              child: widget.friend.avatarUrl == null
                  ? Text(
                      widget.friend.nickname.isNotEmpty
                          ? widget.friend.nickname[0].toUpperCase()
                          : widget.friend.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.friend.nickname.isNotEmpty
                        ? widget.friend.nickname
                        : widget.friend.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '在线',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 更多选项
            },
            tooltip: '更多',
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(_messages[index]);
                        },
                      ),
          ),
          // 输入框
          _buildInputArea(),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '发送一条消息开始聊天吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 消息项
  Widget _buildMessageItem(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对方头像（左侧）
          if (!message.isSentByMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: widget.friend.avatarUrl != null
                  ? NetworkImage(widget.friend.avatarUrl!)
                  : null,
              child: widget.friend.avatarUrl == null
                  ? Text(
                      widget.friend.nickname.isNotEmpty
                          ? widget.friend.nickname[0].toUpperCase()
                          : widget.friend.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // 消息气泡
          Flexible(
            child: Column(
              crossAxisAlignment: message.isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // 根据消息类型显示不同内容
                message.messageType == 'IMAGE' && message.imageUrl != null
                    ? _buildImageMessage(message)
                    : _buildTextMessage(message),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // 自己的头像（右侧）
          if (message.isSentByMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: _apiService.currentUser?.avatarUrl != null
                  ? NetworkImage(_apiService.currentUser!.avatarUrl!)
                  : null,
              child: _apiService.currentUser?.avatarUrl == null
                  ? Text(
                      _apiService.currentUser?.nickname.isNotEmpty == true
                          ? _apiService.currentUser!.nickname[0].toUpperCase()
                          : _apiService.currentUser?.username[0].toUpperCase() ?? '?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// 文本消息气泡
  Widget _buildTextMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: message.isSentByMe
            ? Theme.of(context).primaryColor
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 15,
          color: message.isSentByMe ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  /// 图片消息
  Widget _buildImageMessage(ChatMessage message) {
    return GestureDetector(
      onTap: () {
        // 点击图片查看大图
        _showImagePreview(message.imageUrl!);
      },
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 显示图片预览
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 输入框
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 更多功能按钮
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.grey[600]),
              onPressed: () {
                _showMoreOptions();
              },
              tooltip: '更多',
            ),
            // 发送按钮
            IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _sendMessage,
              tooltip: '发送',
            ),
          ],
        ),
      ),
    );
  }

  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoreOptionItem(
                    icon: Icons.photo_library,
                    label: '相册',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _buildMoreOptionItem(
                    icon: Icons.camera_alt,
                    label: '拍摄',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 更多选项项
  Widget _buildMoreOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.grey[700], size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 2) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}-${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isSentByMe;
  final DateTime timestamp;
  final String messageType; // TEXT 或 IMAGE
  final String? imageUrl; // 图片消息的URL

  ChatMessage({
    required this.id,
    required this.content,
    required this.isSentByMe,
    required this.timestamp,
    this.messageType = 'TEXT',
    this.imageUrl,
  });
}

