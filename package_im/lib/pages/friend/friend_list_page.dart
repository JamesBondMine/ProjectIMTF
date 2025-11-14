import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/friend.dart';
import 'add_friend_page.dart';

/// 好友列表页面
class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  List<Friend> _friendList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriendList();
  }

  /// 加载好友列表
  Future<void> _loadFriendList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用API获取好友列表
      // final response = await ApiService().getFriendList();
      
      // 模拟延迟
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据（实际应该从API获取）
      // setState(() {
      //   _friendList = response.data ?? [];
      //   _sortFriendList();
      // });
      
      setState(() {
        _friendList = [];
      });
    } catch (e) {
      EasyLoading.showError('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 按时间排序（最新的在前面）
  void _sortFriendList() {
    _friendList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 添加好友
  Future<void> _navigateToAddFriend() async {
    final result = await Navigator.of(context).push<Friend>(
      MaterialPageRoute(
        builder: (context) => const AddFriendPage(),
      ),
    );

    // 如果添加成功，刷新列表
    if (result != null) {
      setState(() {
        _friendList.add(result);
        _sortFriendList();
      });
      EasyLoading.showSuccess('添加好友成功！');
    }
  }

  /// 删除好友
  Future<void> _deleteFriend(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友"${friend.displayName}"吗？'),
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

    if (confirm == true) {
      try {
        // TODO: 调用API删除好友
        // await ApiService().deleteFriend(friend.id);
        
        setState(() {
          _friendList.remove(friend);
        });
        
        EasyLoading.showSuccess('删除成功');
      } catch (e) {
        EasyLoading.showError('删除失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToAddFriend,
            tooltip: '添加好友',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friendList.isEmpty
              ? _buildEmptyState()
              : _buildFriendList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFriend,
        tooltip: '添加好友',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// 空状态页面
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            '还没有好友',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右上角添加好友吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _navigateToAddFriend,
            icon: const Icon(Icons.person_add),
            label: const Text('添加好友'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 好友列表
  Widget _buildFriendList() {
    return RefreshIndicator(
      onRefresh: _loadFriendList,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _friendList.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final friend = _friendList[index];
          return _buildFriendItem(friend);
        },
      ),
    );
  }

  /// 好友列表项
  Widget _buildFriendItem(Friend friend) {
    return Dismissible(
      key: Key(friend.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除好友'),
            content: Text('确定要删除好友"${friend.displayName}"吗？'),
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
      },
      onDismissed: (direction) {
        _deleteFriend(friend);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: friend.friendAvatarUrl != null
              ? NetworkImage(friend.friendAvatarUrl!)
              : null,
          child: friend.friendAvatarUrl == null
              ? Text(
                  friend.displayName.isNotEmpty
                      ? friend.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              friend.friendUsername,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(friend.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _deleteFriend(friend);
            } else if (value == 'remark') {
              _showRemarkDialog(friend);
            } else if (value == 'detail') {
              _showFriendDetail(friend);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detail',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('详细信息'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remark',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('设置备注'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除好友', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: 跳转到聊天页面
          EasyLoading.showInfo('开始聊天功能待开发');
        },
      ),
    );
  }

  /// 显示好友详情
  void _showFriendDetail(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('好友信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('昵称', friend.friendNickname),
            _buildDetailRow('账号', friend.friendUsername),
            if (friend.friendPhone != null && friend.friendPhone!.isNotEmpty)
              _buildDetailRow('手机', friend.friendPhone!),
            if (friend.remark != null && friend.remark!.isNotEmpty)
              _buildDetailRow('备注', friend.remark!),
            _buildDetailRow('添加时间', _formatTime(friend.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 设置备注对话框
  void _showRemarkDialog(Friend friend) {
    final controller = TextEditingController(text: friend.remark);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置备注'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 调用API更新备注
              setState(() {
                final index = _friendList.indexOf(friend);
                if (index != -1) {
                  _friendList[index] = friend.copyWith(
                    remark: controller.text.trim(),
                  );
                }
              });
              Navigator.of(context).pop();
              EasyLoading.showSuccess('设置成功');
            },
            child: const Text('确定'),
          ),
        ],
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
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    }
  }
}

