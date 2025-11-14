import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/chat_conversation.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../profile/profile_page.dart';
import '../friend/add_friend_page.dart';
import 'chat_page.dart';

/// 聊天列表页面
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<ChatConversation> _conversationList = [];
  bool _isLoading = false;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadConversationList();
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部用户头像区域
            _buildHeader(),
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
      ),
    );
  }

  /// 顶部头像区域
  Widget _buildHeader() {
    final user = _apiService.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 用户头像（可点击）
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.nickname.isNotEmpty == true
                          ? user!.nickname[0].toUpperCase()
                          : user?.username[0].toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          const Expanded(
            child: Text(
              '聊天',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 搜索好友按钮
          IconButton(
            icon: const Icon(Icons.add),
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
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 120,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '暂无聊天',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '去好友列表找人聊天吧',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '下拉刷新',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversationList.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 72,
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
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: conversation.targetAvatarUrl != null
                  ? NetworkImage(conversation.targetAvatarUrl!)
                  : null,
              child: conversation.targetAvatarUrl == null
                  ? Text(
                      conversation.targetName.isNotEmpty
                          ? conversation.targetName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // 未读消息角标
            if (conversation.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    conversation.unreadCount > 99
                        ? '99+'
                        : conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            // 置顶图标
            if (conversation.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: Colors.orange,
                ),
              ),
            // 免打扰图标
            if (conversation.isMuted)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.notifications_off,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            Expanded(
              child: Text(
                conversation.targetName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatLastMessage(conversation.lastMessage),
          style: TextStyle(
            fontSize: 14,
            color: conversation.unreadCount > 0
                ? Colors.black87
                : Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 20),
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
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除会话', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
}

