import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_conversation.dart';
import '../../models/user.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';
import '../../services/remark_service.dart';
import '../profile/profile_page.dart';
import '../friend/add_friend_page.dart';
import 'chat_page.dart';

/// 聊天列表页面
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  List<ChatConversation> _conversationList = [];
  bool _isLoading = false;
  final _apiService = ApiService();
  final _remarkService = RemarkService();
  Timer? _refreshTimer;  // 定时刷新定时器
  
  // 侧边面板相关
  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;
  bool _isDrawerOpen = false;  // 初始值，实际由设置决定

  @override
  void initState() {
    super.initState();
    
    // 初始化侧边面板动画控制器
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _drawerAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),  // 从左侧隐藏
      end: Offset.zero,  // 显示在屏幕上
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
    
    // 根据设置决定是否展开侧边面板
    _loadDrawerSetting();
    
    // 注册消息监听器
    _apiService.addMessageListener(_onWebSocketMessage);
    
    // 立即加载一次
    _loadConversationList();
    
    // 启动定时器：每8秒自动刷新
    _startAutoRefresh();
  }
  
  /// 加载侧边面板设置
  Future<void> _loadDrawerSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final autoOpen = prefs.getBool('auto_open_drawer') ?? false;  // 默认为 false（关闭）
    
    setState(() {
      _isDrawerOpen = autoOpen;
    });
    
    // 根据设置决定是否展开
    if (autoOpen) {
      _drawerController.forward();
    }
  }

  @override
  void dispose() {
    // 取消定时器
    _refreshTimer?.cancel();
    
    // 释放动画控制器
    _drawerController.dispose();
    
    // 移除消息监听器
    _apiService.removeMessageListener(_onWebSocketMessage);
    
    super.dispose();
  }
  
  /// 切换侧边面板
  void _toggleDrawer() {
    setState(() {
      if (_isDrawerOpen) {
        _drawerController.reverse();
      } else {
        _drawerController.forward();
      }
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  /// 启动自动刷新定时器
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        debugPrint('🔄 [ChatListPage] 定时静默刷新会话列表');
        _silentRefresh(); // 使用静默刷新，避免闪烁
      }
    });
    debugPrint('✅ [ChatListPage] 已启动定时刷新（每8秒）');
  }

  /// 处理 WebSocket 接收到的消息
  void _onWebSocketMessage(Message message) {
    try {
      debugPrint('📨 [ChatListPage] 收到 WebSocket 消息: id=${message.id}, sender=${message.senderId}, receiver=${message.receiverId}');
      
      final currentUserId = _apiService.currentUser?.id;
      
      // 只处理与当前用户相关的消息
      if (message.senderId == currentUserId || message.receiverId == currentUserId) {
        debugPrint('✅ [ChatListPage] 收到新消息，静默刷新会话列表');
        // 延迟一下刷新，确保后端已经更新了会话列表，使用静默刷新避免闪烁
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _silentRefresh(); // 使用静默刷新，避免闪烁
          }
        });
      }
    } catch (e) {
      debugPrint('❌ [ChatListPage] 处理 WebSocket 消息失败: $e');
    }
  }

  /// 加载会话列表
  Future<void> _loadConversationList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用API获取会话列表
      final response = await _apiService.getConversationList();

      if (response.success && response.data != null) {
        setState(() {
          _conversationList = response.data!;
          _sortConversationList();
        });
      } else {
        if (response.message.isNotEmpty) {
          EasyLoading.showError(response.message);
        }
      }
    } catch (e) {
      EasyLoading.showError('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 静默刷新会话列表（不显示加载状态，避免闪烁）
  Future<void> _silentRefresh() async {
    try {
      // 调用API获取会话列表
      final response = await _apiService.getConversationList();

      if (response.success && response.data != null) {
        setState(() {
          _conversationList = response.data!;
          _sortConversationList();
        });
      }
    } catch (e) {
      debugPrint('❌ [ChatListPage] 静默刷新失败: $e');
    }
  }

  /// 排序会话列表（置顶的在前面，然后按时间排序）
  void _sortConversationList() {
    _conversationList.sort((a, b) {
      // 置顶的在前面
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // 按时间倒序
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });
  }

  /// 删除会话
  Future<void> _deleteConversation(ChatConversation conversation) async {
    try {
      // 调用API删除会话
      final response = await _apiService.deleteConversation(conversation.id);
      
      if (response.success) {
        setState(() {
          _conversationList.remove(conversation);
        });
        
        EasyLoading.showSuccess('删除成功');
      } else {
        EasyLoading.showError(response.message.isEmpty ? '删除失败' : response.message);
      }
    } catch (e) {
      EasyLoading.showError('删除失败: $e');
    }
  }

  /// 置顶/取消置顶
  Future<void> _togglePin(ChatConversation conversation) async {
    try {
      // TODO: 调用API设置置顶
      // await ApiService().togglePin(conversation.id, !conversation.isPinned);
      
      setState(() {
        final index = _conversationList.indexOf(conversation);
        if (index != -1) {
          _conversationList[index] = conversation.copyWith(
            isPinned: !conversation.isPinned,
          );
          _sortConversationList();
        }
      });
      
      EasyLoading.showSuccess(
        conversation.isPinned ? '取消置顶' : '置顶成功',
      );
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  /// 免打扰/取消免打扰
  Future<void> _toggleMute(ChatConversation conversation) async {
    try {
      // TODO: 调用API设置免打扰
      // await ApiService().toggleMute(conversation.id, !conversation.isMuted);
      
      setState(() {
        final index = _conversationList.indexOf(conversation);
        if (index != -1) {
          _conversationList[index] = conversation.copyWith(
            isMuted: !conversation.isMuted,
          );
        }
      });
      
      EasyLoading.showSuccess(
        conversation.isMuted ? '取消免打扰' : '消息免打扰',
      );
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏为透明，图标为深色以配合白色背景
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,  // 深色图标
        statusBarBrightness: Brightness.light,  // iOS 使用
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // 主内容区域
          Column(
            children: [
              // 顶部用户头像区域（包含状态栏）
              _buildHeader(context),
              // 聊天列表（包含下拉刷新）
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadConversationList,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _conversationList.isEmpty
                          ? _buildEmptyState()
                          : _buildConversationList(),
                ),
              ),
            ],
          ),
          
          // 遮罩层（当侧边面板打开时显示）
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: AnimatedOpacity(
                opacity: _isDrawerOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black,
                ),
              ),
            ),
          
          // 左侧滑出的个人中心面板
          SlideTransition(
            position: _drawerAnimation,
            child: _buildProfileDrawer(),
          ),
        ],
      ),
    );
  }

  /// 顶部头像区域（包含状态栏）- 极简白色设计
  Widget _buildHeader(BuildContext context) {
    final user = _apiService.currentUser;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 大标题
              const Text(
                '消息',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              // 添加好友按钮 - 圆形图标
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddFriendPage(),
                      ),
                    ).then((_) {
                      _loadConversationList();
                    });
                  },
                  tooltip: '添加好友',
                ),
              ),
              const SizedBox(width: 4),
              // 用户头像（可点击）- 大圆形设计
              GestureDetector(
                onTap: _toggleDrawer,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: user?.avatarUrl != null
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user!.avatarUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Center(
                                  child: Text(
                                    user.nickname.isNotEmpty
                                        ? user.nickname[0].toUpperCase()
                                        : user.username[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            user?.nickname.isNotEmpty == true
                                ? user!.nickname[0].toUpperCase()
                                : user?.username[0].toUpperCase() ?? '?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 空状态页面（支持下拉刷新）- 极简设计
  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 空状态图标 - 简洁设计
                    Icon(
                      Icons.forum_outlined,
                      size: 120,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 32),
                    // 标题
                    Text(
                      '暂无聊天',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 副标题
                    Text(
                      '去好友列表找人聊天吧',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 会话列表 - 极简设计
  Widget _buildConversationList() {
    return Container(
      color: Colors.white,  // 白色背景
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 0),
        itemCount: _conversationList.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          indent: 96,  // 对齐内容区域
          endIndent: 20,
          color: Colors.grey[100],
        ),
        itemBuilder: (context, index) {
          final conversation = _conversationList[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  /// 会话列表项 - 极简设计
  Widget _buildConversationItem(ChatConversation conversation) {
    // 根据用户ID生成颜色（每个用户有固定的颜色）
    final colorIndex = (int.tryParse(conversation.targetId) ?? 0) % 8;
    final accentColors = [
      Theme.of(context).primaryColor,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    final accentColor = accentColors[colorIndex];

    return Container(
      decoration: BoxDecoration(
        color: conversation.unreadCount > 0
            ? Theme.of(context).primaryColor.withOpacity(0.03)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 跳转到聊天页面
            final friend = User(
              id: int.tryParse(conversation.targetId) ?? 0,
              username: conversation.targetName,
              email: '',
              nickname: conversation.targetName,
              avatarUrl: conversation.targetAvatarUrl,
              phone: null,
              status: 'ACTIVE',
              userType: 'NORMAL',
              isGuest: false,
              createdAt: '',
              updatedAt: '',
            );

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  friend: friend,
                  conversationId: int.tryParse(conversation.id),
                ),
              ),
            ).then((_) {
              _loadConversationList();
            });
          },
          child: Row(
            children: [
              // 左侧彩色竖条
              Container(
                width: 4,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: conversation.unreadCount > 0
                        ? [accentColor, accentColor.withOpacity(0.3)]
                        : [Colors.transparent, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 头像
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: conversation.unreadCount > 0
                            ? accentColor.withOpacity(0.3)
                            : Colors.grey[200]!,
                        width: 2,
                      ),
                    ),
                    child: conversation.targetAvatarUrl != null
                        ? CircleAvatar(
                            radius: 30,
                            backgroundColor: accentColor.withOpacity(0.1),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: conversation.targetAvatarUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: accentColor.withOpacity(0.1),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: accentColor.withOpacity(0.1),
                                  child: Center(
                                    child: Text(
                                      conversation.targetName.isNotEmpty
                                          ? conversation.targetName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundColor: accentColor.withOpacity(0.1),
                            child: Text(
                              conversation.targetName.isNotEmpty
                                  ? conversation.targetName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 24,
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  // 未读角标
                  if (conversation.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // 内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 第一行：名称、时间、操作
                    Row(
                      children: [
                        // 名称
                        Expanded(
                          child: FutureBuilder<String?>(
                            future: _remarkService.getRemark(int.tryParse(conversation.targetId) ?? 0),
                            builder: (context, snapshot) {
                              final displayName = snapshot.data ?? conversation.targetName;
                              return Row(
                                children: [
                                  // 置顶图标
                                  if (conversation.isPinned)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.push_pin_rounded,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: conversation.unreadCount > 0
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: Colors.black87,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // 时间
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: conversation.unreadCount > 0
                                ? accentColor
                                : Colors.grey[500],
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        // 更多按钮
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                          padding: EdgeInsets.zero,
                          offset: const Offset(-12, 0),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteDialog(conversation);
                            } else if (value == 'pin') {
                              _togglePin(conversation);
                            } else if (value == 'mute') {
                              _toggleMute(conversation);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                    conversation.isPinned
                                        ? Icons.push_pin_outlined
                                        : Icons.push_pin,
                                    size: 18,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    conversation.isPinned ? '取消置顶' : '置顶',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'mute',
                              child: Row(
                                children: [
                                  Icon(
                                    conversation.isMuted
                                        ? Icons.notifications_active_outlined
                                        : Icons.notifications_off_outlined,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    conversation.isMuted ? '取消免打扰' : '免打扰',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('删除会话', style: TextStyle(color: Colors.red, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 第二行：最后消息和免打扰图标
                    Row(
                      children: [
                        // 免打扰图标
                        if (conversation.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        // 最后消息
                        Expanded(
                          child: Text(
                            _formatLastMessage(conversation.lastMessage),
                            style: TextStyle(
                              fontSize: 14,
                              color: conversation.unreadCount > 0
                                  ? Colors.black.withOpacity(0.6)
                                  : Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示删除对话框
  void _showDeleteDialog(ChatConversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除与"${conversation.targetName}"的聊天吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteConversation(conversation);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化最后一条消息
  String _formatLastMessage(String message) {
    // 判断是否是图片消息（URL格式）
    if (message.startsWith('http://') || message.startsWith('https://')) {
      // 判断是否是图片URL（包含常见图片扩展名或来自文件服务）
      if (message.contains('/files/') || 
          message.endsWith('.jpg') || 
          message.endsWith('.jpeg') || 
          message.endsWith('.png') || 
          message.endsWith('.gif') || 
          message.endsWith('.webp')) {
        return '[图片]';
      }
    }
    return message;
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      // 今天，显示时间
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      // 昨天
      return '昨天';
    } else if (diff.inDays < 7) {
      // 一周内，显示星期
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    } else {
      // 更早，显示日期
      return '${time.month}/${time.day}';
    }
  }

  /// 构建左侧滑出的个人中心面板
  Widget _buildProfileDrawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,  // 宽度为屏幕的75%
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ProfilePage(
        onClose: _toggleDrawer,  // 传递关闭回调
      ),
    );
  }
}

