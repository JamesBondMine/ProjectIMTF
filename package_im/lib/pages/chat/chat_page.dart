import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../models/user.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';
import '../../services/remark_service.dart';
import '../friend/friend_detail_page.dart';
import 'video_player_page.dart';

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
  final _remarkService = RemarkService();
  final _imagePicker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isLoading = false;
  bool _isSpeaking = false; // 是否正在朗读
  String? _friendRemark; // 好友备注

  // GIF表情列表
  static const List<String> _gifList = [
    'assets/gif/car-1803_256.gif',
    'assets/gif/cupid-18601_256.gif',
    'assets/gif/download-2486_256.gif',
    'assets/gif/flower-11997_256.gif',
    'assets/gif/flowers-11015_256.gif',
    'assets/gif/halloween-22525_256.gif',
    'assets/gif/hammer-8415_256.gif',
    'assets/gif/horse-22647_256.gif',
    'assets/gif/hot-12616_256.gif',
    'assets/gif/hot-air-balloon-3622_256.gif',
    'assets/gif/iceland-5543_256.gif',
    'assets/gif/ladybug-5068_256.gif',
    'assets/gif/love-3955_256.gif',
    'assets/gif/paper-23984_256.gif',
    'assets/gif/pinwheel-8829_256.gif',
    'assets/gif/pride-6390_256.gif',
    'assets/gif/rocket-3972_256.gif',
    'assets/gif/swing-6077_256.gif',
    'assets/gif/tree-10000_256.gif',
    'assets/gif/unicorn-16249_256.gif',
    'assets/gif/wind-21844_256.gif',
    'assets/gif/winter-16014_256.gif',
  ];

  @override
  void initState() {
    super.initState();
    
    // 注册消息监听器（WebSocket 已在 HomePage 建立连接）
    _apiService.addMessageListener(_onWebSocketMessage);
    
    // 初始化 TTS
    _initTts();
    
    // 加载好友备注
    _loadFriendRemark();
    
    debugPrint('📱 [ChatPage] 已注册消息监听器，等待实时消息');
    
    // 如果有conversationId，加载历史消息；否则加载模拟数据
    if (widget.conversationId != null) {
      _loadHistoryMessages();
      // 标记消息为已读
      _markMessagesAsRead();
    } else {
      _loadMockMessages();
    }
  }

  /// 初始化 TTS
  Future<void> _initTts() async {
    try {
      // 设置语言为简体中文
      await _flutterTts.setLanguage("zh-CN");
      
      // 设置语速（0.0 - 1.0，默认 0.5）
      await _flutterTts.setSpeechRate(0.5);
      
      // 设置音量（0.0 - 1.0，默认 1.0）
      await _flutterTts.setVolume(1.0);
      
      // 设置音调（0.5 - 2.0，默认 1.0）
      await _flutterTts.setPitch(1.0);

      // 监听朗读完成事件
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
        debugPrint('🔊 朗读完成');
      });

      // 监听朗读开始事件
      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
        debugPrint('🔊 开始朗读');
      });

      // 监听朗读错误事件
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
        debugPrint('❌ 朗读错误: $msg');
        EasyLoading.showError('朗读失败');
      });

      debugPrint('✅ TTS 初始化成功');
    } catch (e) {
      debugPrint('❌ TTS 初始化失败: $e');
    }
  }

  /// 加载好友备注
  Future<void> _loadFriendRemark() async {
    final remark = await _remarkService.getRemark(widget.friend.id);
    if (mounted) {
      setState(() {
        _friendRemark = remark;
      });
    }
  }

  @override
  void dispose() {
    // 移除消息监听器（但不断开 WebSocket 连接，保持全局连接）
    _apiService.removeMessageListener(_onWebSocketMessage);
    
    // 停止 TTS
    _flutterTts.stop();
    
    debugPrint('📱 [ChatPage] 已移除消息监听器');
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  /// 判断 URL 是否是视频文件
  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv', '.webm', '.m4v'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  /// 处理 WebSocket 接收到的消息
  void _onWebSocketMessage(Message message) {
    try {
      debugPrint('📨 [ChatPage] 收到 WebSocket 消息: id=${message.id}, sender=${message.senderId}, receiver=${message.receiverId}, messageType=${message.messageType}, content=${message.content}');
      
      final currentUserId = _apiService.currentUser?.id;
      final friendId = widget.friend.id;
      
      // 判断消息是否属于当前会话
      // 1. 对方发给我的：senderId == friendId && receiverId == currentUserId
      // 2. 我发给对方的（其他设备）：senderId == currentUserId && receiverId == friendId
      final isFromFriend = (message.senderId == friendId && message.receiverId == currentUserId);
      final isToFriend = (message.senderId == currentUserId && message.receiverId == friendId);
      
      if (isFromFriend || isToFriend) {
        // 检查消息是否已存在（避免重复）
        final exists = _messages.any((m) => m.id == message.id.toString());
        if (exists) {
          debugPrint('⚠️ 消息已存在，跳过: ${message.id}');
          return;
        }
        
        // 🔑 判断 FILE 类型是否为视频
        final isVideo = message.messageType == 'FILE' && _isVideoUrl(message.content);
        
        final chatMessage = ChatMessage(
          id: message.id.toString(),
          content: message.content,
          isSentByMe: isToFriend,  // 我发的消息
          timestamp: DateTime.parse(message.createdAt),
          messageType: message.messageType,
          imageUrl: message.messageType == 'IMAGE' ? message.content : null,
          videoUrl: isVideo ? message.content : null, // FILE类型的视频也要设置videoUrl
        );
        
        if (mounted) {
          setState(() {
            _messages.add(chatMessage);
          });
          
          // 滚动到底部
          _scrollToBottom();
          
          debugPrint('✅ [ChatPage] 已添加消息到聊天列表: ${message.content}');
          
          // 如果是对方发来的消息，自动标记为已读
          if (isFromFriend) {
            _markMessagesAsRead();
            debugPrint('✅ [ChatPage] 对方的消息已自动标记为已读');
          }
        }
      } else {
        debugPrint('ℹ️  [ChatPage] 消息不属于当前会话，忽略');
      }
    } catch (e) {
      debugPrint('❌ [ChatPage] 处理 WebSocket 消息失败: $e');
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
        
        debugPrint('📥 收到 ${response.data!.length} 条历史消息');
        
        // 转换消息列表
        final messages = response.data!.map((message) {
          debugPrint('历史消息: id=${message.id}, messageType=${message.messageType}, content=${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');
          
          // 🔑 判断 FILE 类型是否为视频
          final isVideo = message.messageType == 'FILE' && _isVideoUrl(message.content);
          
          return ChatMessage(
            id: message.id.toString(),
            content: message.content,
            isSentByMe: message.senderId == currentUserId,
            timestamp: DateTime.parse(message.createdAt),
            messageType: message.messageType,
            imageUrl: message.messageType == 'IMAGE' ? message.content : null,
            videoUrl: isVideo ? message.content : null, // FILE类型的视频也要设置videoUrl
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

  /// 选择并发送视频
  Future<void> _pickAndSendVideo(ImageSource source) async {
    try {
      // 1. 选择视频
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 最长5分钟
      );

      if (video == null) return;

      // 显示加载提示
      EasyLoading.show(status: '上传中...');

      // 2. 上传视频获取URL（暂时跳过压缩步骤，直接上传原视频）
      final uploadResult = await _apiService.uploadSingleFile(video.path);

      if (!uploadResult.success || uploadResult.data == null) {
        EasyLoading.showError('视频上传失败');
        return;
      }

      String videoUrl = uploadResult.data!;
      debugPrint('✅ 视频上传成功: $videoUrl');

      // 3. 先添加到本地列表（乐观更新）
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: videoUrl, // content 直接是视频 URL
        isSentByMe: true,
        timestamp: DateTime.now(),
        messageType: 'FILE', // 视频消息使用 FILE 类型
        videoUrl: videoUrl,
      );

      setState(() {
        _messages.add(tempMessage);
      });

      // 滚动到底部
      _scrollToBottom();

      // 4. 发送视频消息（messageType: FILE）
      bool success = false;

      // 优先尝试通过 WebSocket 发送
      if (_apiService.isChatWebSocketConnected) {
        debugPrint('📤 尝试通过 WebSocket 发送视频...');
        success = await _apiService.sendMessageViaWebSocket(
          receiverId: widget.friend.id,
          content: videoUrl,
          messageType: 'FILE', // 🔑 视频使用 FILE 类型
        );
        
        if (success) {
          debugPrint('✅ WebSocket 发送视频成功');
          EasyLoading.dismiss();
          return;
        } else {
          debugPrint('⚠️ WebSocket 发送视频失败，降级到 HTTP');
        }
      } else {
        debugPrint('⚠️ WebSocket 未连接，使用 HTTP 发送视频');
      }

      // WebSocket 失败或未连接，使用 HTTP 发送
      final response = await _apiService.sendMessage(
        receiverId: widget.friend.id,
        content: videoUrl, // 视频消息的content是视频URL
        messageType: 'FILE', // 🔑 视频使用 FILE 类型
      );

      EasyLoading.dismiss();

      if (!response.success) {
        if (mounted) {
          EasyLoading.showError(response.message.isEmpty ? '发送失败' : response.message);
        }
      } else {
        debugPrint('✅ HTTP 发送视频成功: ${response.data?.id}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        EasyLoading.showError('发送失败: $e');
      }
      debugPrint('❌ 发送视频失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            // 头像（方形）
            widget.friend.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: widget.friend.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            widget.friend.nickname.isNotEmpty
                                ? widget.friend.nickname[0].toUpperCase()
                                : widget.friend.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        widget.friend.nickname.isNotEmpty
                            ? widget.friend.nickname[0].toUpperCase()
                            : widget.friend.username[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _friendRemark ?? (widget.friend.nickname.isNotEmpty
                        ? widget.friend.nickname
                        : widget.friend.username),
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
            onPressed: () async {
              // 跳转到好友详情页面
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FriendDetailPage(friend: widget.friend),
                ),
              );
              // 返回后重新加载备注
              _loadFriendRemark();
            },
            tooltip: '好友详情',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白处隐藏键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // 消息列表（带背景图）
            Expanded(
              child: Stack(
                children: [
                  // 背景图片
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/chat_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 消息列表
                  _isLoading
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
                ],
              ),
            ),
            // 输入框
            _buildInputArea(),
          ],
        ),
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
          // 对方头像（左侧，方形）
          if (!message.isSentByMe) ...[
            widget.friend.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: widget.friend.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            widget.friend.nickname.isNotEmpty
                                ? widget.friend.nickname[0].toUpperCase()
                                : widget.friend.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        widget.friend.nickname.isNotEmpty
                            ? widget.friend.nickname[0].toUpperCase()
                            : widget.friend.username[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          // 消息气泡
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Column(
                crossAxisAlignment: message.isSentByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // 根据消息类型显示不同内容
                  message.messageType == 'IMAGE' && message.imageUrl != null
                      ? _buildImageMessage(message)
                      : message.videoUrl != null // 🔑 根据videoUrl判断是否为视频（支持FILE类型）
                          ? _buildVideoMessage(message)
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
          ),
          // 自己的头像（右侧，方形）
          if (message.isSentByMe) ...[
            const SizedBox(width: 8),
            _apiService.currentUser?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: _apiService.currentUser!.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 36,
                        height: 36,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            _apiService.currentUser?.nickname.isNotEmpty == true
                                ? _apiService.currentUser!.nickname[0].toUpperCase()
                                : _apiService.currentUser?.username[0].toUpperCase() ?? '?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _apiService.currentUser?.nickname.isNotEmpty == true
                            ? _apiService.currentUser!.nickname[0].toUpperCase()
                            : _apiService.currentUser?.username[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

  /// 图片消息（包括普通图片和GIF）
  Widget _buildImageMessage(ChatMessage message) {
    // 判断是本地 assets 路径还是网络 URL
    final isLocalAsset = message.imageUrl!.startsWith('assets/');
    
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
          child: isLocalAsset
              ? Image.asset(
                  message.imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
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
                  ),
                ),
        ),
      ),
    );
  }

  /// 视频消息
  Widget _buildVideoMessage(ChatMessage message) {
    return GestureDetector(
      onTap: () {
        // 点击视频播放
        _showVideoPlayer(message.videoUrl!);
      },
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 200,
                height: 200,
                color: Colors.black87,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // 播放按钮
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示视频播放器
  void _showVideoPlayer(String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(videoUrl: videoUrl),
      ),
    );
  }

  /// 显示图片预览
  void _showImagePreview(String imageUrl) {
    // 判断是本地资源还是网络图片
    final isLocalAsset = imageUrl.startsWith('assets/');
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: isLocalAsset
                      ? Image.asset(
                          imageUrl,
                          fit: BoxFit.contain,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.black54,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // 关闭按钮
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
              // 保存按钮
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _saveImageToGallery(imageUrl);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('保存到相册'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 保存图片到相册
  Future<void> _saveImageToGallery(String imageUrl) async {
    try {
      // 1. 请求存储权限
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          EasyLoading.showError('需要相册权限才能保存图片');
          return;
        }
      }

      EasyLoading.show(status: '保存中...');

      Uint8List imageData;

      // 2. 获取图片数据
      if (imageUrl.startsWith('assets/')) {
        // 本地资源，从 assets 加载
        final byteData = await rootBundle.load(imageUrl);
        imageData = byteData.buffer.asUint8List();
      } else {
        // 网络图片，下载
        final response = await Dio().get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        imageData = response.data;
      }

      // 3. 保存到相册
      final result = await ImageGallerySaver.saveImage(
        imageData,
        quality: 100,
        name: 'chat_image_${DateTime.now().millisecondsSinceEpoch}',
      );

      EasyLoading.dismiss();

      if (result['isSuccess'] == true) {
        EasyLoading.showSuccess('图片已保存到相册');
      } else {
        EasyLoading.showError('保存失败');
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('❌ 保存图片失败: $e');
      EasyLoading.showError('保存失败: $e');
    }
  }

  /// 朗读文本
  Future<void> _speakText(String text) async {
    try {
      if (_isSpeaking) {
        // 如果正在朗读，先停止
        await _flutterTts.stop();
        setState(() {
          _isSpeaking = false;
        });
        return;
      }

      await _flutterTts.speak(text);
      debugPrint('🔊 开始朗读: $text');
    } catch (e) {
      debugPrint('❌ 朗读失败: $e');
      EasyLoading.showError('朗读失败');
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  /// 停止朗读
  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      debugPrint('🔊 停止朗读');
    } catch (e) {
      debugPrint('❌ 停止朗读失败: $e');
    }
  }

  /// 显示消息操作选项
  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              // 朗读文本消息
              if (message.messageType == 'TEXT')
                ListTile(
                  leading: Icon(
                    _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                    color: _isSpeaking ? Colors.red : null,
                  ),
                  title: Text(_isSpeaking ? '停止朗读' : '朗读'),
                  onTap: () {
                    Navigator.pop(context);
                    if (_isSpeaking) {
                      _stopSpeaking();
                    } else {
                      _speakText(message.content);
                    }
                  },
                ),
              // 复制文本消息
              if (message.messageType == 'TEXT')
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('复制'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.content));
                    EasyLoading.showSuccess('已复制到剪贴板');
                  },
                ),
              // 分享文本消息
              if (message.messageType == 'TEXT')
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('分享'),
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(message.content);
                  },
                ),
              // 保存图片
              if (message.messageType == 'IMAGE' && message.imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('保存图片'),
                  onTap: () {
                    Navigator.pop(context);
                    _saveImageToGallery(message.imageUrl!);
                  },
                ),
              // 分享图片
              if (message.messageType == 'IMAGE' && message.imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('分享图片'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _shareImage(message.imageUrl!);
                  },
                ),
              // 取消
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('取消'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 分享图片
  Future<void> _shareImage(String imageUrl) async {
    try {
      EasyLoading.show(status: '准备分享...');

      // 1. 下载图片
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // 2. 保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.data);

      EasyLoading.dismiss();

      // 3. 分享图片
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '来自聊天的图片',
      );
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('❌ 分享图片失败: $e');
      EasyLoading.showError('分享失败: $e');
    }
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
                  _buildMoreOptionItem(
                    icon: Icons.video_library,
                    label: '视频',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendVideo(ImageSource.gallery);
                    },
                  ),
                  _buildMoreOptionItem(
                    icon: Icons.gif_box,
                    label: 'GIF',
                    onTap: () {
                      Navigator.pop(context);
                      _showGifPicker();
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

  /// 显示GIF选择器
  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 450,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '选择GIF表情',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '共${_gifList.length}个',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _gifList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _sendGif(_gifList[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _gifList[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 发送GIF消息
  Future<void> _sendGif(String gifPath) async {
    try {
      // 显示加载提示
      EasyLoading.show(status: '发送中...');

      // 1. 将 GIF 从 assets 复制到临时目录，然后上传
      final byteData = await rootBundle.load(gifPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/gif_${DateTime.now().millisecondsSinceEpoch}.gif');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // 2. 上传 GIF 到服务器
      final uploadResult = await _apiService.uploadSingleFile(tempFile.path);

      if (!uploadResult.success || uploadResult.data == null) {
        EasyLoading.showError('GIF上传失败');
        return;
      }

      String gifUrl = uploadResult.data!;
      debugPrint('✅ GIF上传成功: $gifUrl');

      // 3. 先添加到本地列表（乐观更新），使用服务器URL
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: gifUrl,
        isSentByMe: true,
        timestamp: DateTime.now(),
        messageType: 'IMAGE',
        imageUrl: gifUrl,
      );

      setState(() {
        _messages.add(tempMessage);
      });

      // 滚动到底部
      _scrollToBottom();

      bool success = false;

      // 4. 优先尝试通过 WebSocket 发送
      if (_apiService.isChatWebSocketConnected) {
        debugPrint('📤 尝试通过 WebSocket 发送GIF: messageType=IMAGE, content=$gifUrl');
        success = await _apiService.sendMessageViaWebSocket(
          receiverId: widget.friend.id,
          content: gifUrl,
          messageType: 'IMAGE',
        );
        
        if (success) {
          debugPrint('✅ WebSocket 发送GIF成功: messageType=IMAGE');
          EasyLoading.dismiss();
          return;
        } else {
          debugPrint('⚠️ WebSocket 发送GIF失败，降级到 HTTP');
        }
      } else {
        debugPrint('⚠️ WebSocket 未连接，使用 HTTP 发送GIF');
      }

      // 5. WebSocket 失败或未连接，使用 HTTP 发送
      debugPrint('📤 通过 HTTP 发送GIF: messageType=IMAGE, content=$gifUrl');
      final response = await _apiService.sendMessage(
        receiverId: widget.friend.id,
        content: gifUrl,
        messageType: 'IMAGE',
      );

      EasyLoading.dismiss();

      if (!response.success) {
        if (mounted) {
          EasyLoading.showError(response.message.isEmpty ? '发送失败' : response.message);
        }
      } else {
        debugPrint('✅ HTTP 发送GIF成功: id=${response.data?.id}, messageType=${response.data?.messageType}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        EasyLoading.showError('发送失败: $e');
      }
      debugPrint('❌ 发送GIF失败: $e');
    }
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
  final String messageType; // TEXT, IMAGE, FILE (FILE类型可用于视频)
  final String? imageUrl; // 图片消息的URL
  final String? videoUrl; // 视频消息的URL（当messageType为FILE且URL是视频格式时）

  ChatMessage({
    required this.id,
    required this.content,
    required this.isSentByMe,
    required this.timestamp,
    this.messageType = 'TEXT',
    this.imageUrl,
    this.videoUrl,
  });
}
