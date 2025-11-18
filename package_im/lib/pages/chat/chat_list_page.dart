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
    final autoOpen = prefs.getBool('auto_open_drawer') ?? true;  // 默认为 true
    
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
    // 设置状态栏为透明，图标为深色
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
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

  /// 顶部头像区域（包含状态栏）
  Widget _buildHeader(BuildContext context) {
    final user = _apiService.currentUser;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,  // 状态栏高度 + 额外间距
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 用户头像（可点击）- 加大尺寸
          GestureDetector(
            onTap: _toggleDrawer,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: user?.avatarUrl != null
                  ? CircleAvatar(
                      radius: 26,  // 从20增大到26
                      backgroundColor: Theme.of(context).primaryColor,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user!.avatarUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).primaryColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).primaryColor,
                            child: Center(
                              child: Text(
                                user.nickname.isNotEmpty
                                    ? user.nickname[0].toUpperCase()
                                    : user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,  // 字体也相应增大
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 26,  // 从20增大到26
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user?.nickname.isNotEmpty == true
                            ? user!.nickname[0].toUpperCase()
                            : user?.username[0].toUpperCase() ?? '?',
                        style: const TextStyle(
                          fontSize: 22,  // 字体也相应增大
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),  // 增加间距
          // 显示用户账号
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.nickname.isNotEmpty == true
                      ? user!.nickname
                      : user?.username ?? '用户',
                  style: const TextStyle(
                    fontSize: 20,  // 从18增大到20
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (user?.username != null)
                  Text(
                    user!.username,
                    style: TextStyle(
                      fontSize: 13,  // 从12增大到13
                      color: Colors.grey[600],
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // 搜索好友按钮
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.person_add_rounded,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddFriendPage(),
                  ),
                ).then((_) {
                  // 从添加好友页面返回后刷新会话列表
                  _loadConversationList();
                });
              },
              tooltip: '添加好友',
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态页面（支持下拉刷新）
  Widget _buildEmptyState() {
    return LayoutBuilder(
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
                  // 空状态图标 - 优化样式
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 80,
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '暂无聊天',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '去好友列表找人聊天吧',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 下拉刷新提示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '下拉刷新',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 会话列表
  Widget _buildConversationList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _conversationList.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 88,  // 对齐头像右侧
        endIndent: 20,
        color: Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final conversation = _conversationList[index];
        return _buildConversationItem(conversation);
      },
    );
  }

  /// 会话列表项
  Widget _buildConversationItem(ChatConversation conversation) {
    return Dismissible(
      key: Key(conversation.id),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.push_pin,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 左滑置顶
          _togglePin(conversation);
          return false;
        } else {
          // 右滑删除
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('删除会话'),
              content: Text('确定要删除与"${conversation.targetName}"的聊天吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteConversation(conversation);
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),  // 增加内边距
        leading: Stack(
          children: [
            // 好友头像 - 缩小尺寸
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: conversation.targetAvatarUrl != null
                  ? CircleAvatar(
                      radius: 24,  // 从28缩小到24
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: conversation.targetAvatarUrl!,
                          width: 48,  // 从56缩小到48
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
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
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                conversation.targetName.isNotEmpty
                                    ? conversation.targetName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 18,  // 从20缩小到18
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
                      radius: 24,  // 从28缩小到24
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        conversation.targetName.isNotEmpty
                            ? conversation.targetName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 18,  // 从20缩小到18
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            // 未读消息角标 - 优化样式和位置
            if (conversation.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            // 置顶图标 - 优化样式
            if (conversation.isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 16,
                  color: Colors.orange[700],
                ),
              ),
            // 免打扰图标 - 优化样式
            if (conversation.isMuted)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.notifications_off_rounded,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            Expanded(
              child: FutureBuilder<String?>(
                future: _remarkService.getRemark(int.tryParse(conversation.targetId) ?? 0),
                builder: (context, snapshot) {
                  final displayName = snapshot.data ?? conversation.targetName;
                  return Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 17,  // 从16增大到17
                      fontWeight: FontWeight.w600,  // 从w500加粗到w600
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),  // 增加标题和副标题的间距
          child: Text(
            _formatLastMessage(conversation.lastMessage),
            style: TextStyle(
              fontSize: 14,
              color: conversation.unreadCount > 0
                  ? Colors.black.withOpacity(0.7)  // 未读消息深色
                  : Colors.grey[600],  // 已读消息灰色
              height: 1.3,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: SizedBox(
          width: 80,  // 固定宽度，避免布局抖动
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 时间显示 - 优化样式
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: conversation.unreadCount > 0 
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatTime(conversation.lastMessageTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: conversation.unreadCount > 0
                        ? Theme.of(context).primaryColor
                        : Colors.grey[500],
                    fontWeight: conversation.unreadCount > 0 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 更多按钮 - 优化样式
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Colors.grey[400],
                ),
                padding: EdgeInsets.zero,
                iconSize: 20,
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
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('删除会话', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () {
          // 跳转到聊天页面
          // 构建对方用户信息
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
            // 从聊天页面返回后刷新会话列表
            _loadConversationList();
          });
        },
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

