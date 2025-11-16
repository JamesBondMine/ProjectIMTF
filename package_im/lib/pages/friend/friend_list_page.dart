import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/remark_service.dart';
import 'add_friend_page.dart';
import 'friend_detail_page.dart';

/// 好友列表页面
class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  List<User> _friendList = [];
  bool _isLoading = false;
  final _apiService = ApiService();
  final _remarkService = RemarkService();

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
      // 调用API获取好友列表
      final response = await _apiService.getFriendList();
      
      if (response.success && response.data != null) {
        setState(() {
          _friendList = response.data!;
          _sortFriendList();
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

  /// 按用户名排序（字母顺序）
  void _sortFriendList() {
    _friendList.sort((a, b) {
      final nameA = a.nickname.isNotEmpty ? a.nickname : a.username;
      final nameB = b.nickname.isNotEmpty ? b.nickname : b.username;
      return nameA.compareTo(nameB);
    });
  }

  /// 添加好友
  Future<void> _navigateToAddFriend() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddFriendPage(),
      ),
    );

    // 如果添加成功，刷新列表
    if (result == true) {
      _loadFriendList();
    }
  }

  /// 删除好友
  Future<void> _deleteFriend(User friend) async {
    final displayName = friend.nickname.isNotEmpty ? friend.nickname : friend.username;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友"$displayName"吗？'),
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
        child: const Icon(Icons.add),
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
  Widget _buildFriendItem(User friend) {
    return Dismissible(
      key: Key(friend.id.toString()),
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
        final displayName = friend.nickname.isNotEmpty ? friend.nickname : friend.username;
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除好友'),
            content: Text('确定要删除好友"$displayName"吗？'),
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
        leading: friend.avatarUrl != null
            ? CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: friend.avatarUrl!,
                    width: 40,
                    height: 40,
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
                          friend.nickname.isNotEmpty
                              ? friend.nickname[0].toUpperCase()
                              : friend.username[0].toUpperCase(),
                          style: TextStyle(
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
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  friend.nickname.isNotEmpty
                      ? friend.nickname[0].toUpperCase()
                      : friend.username[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: FutureBuilder<String?>(
          future: _remarkService.getRemark(friend.id),
          builder: (context, snapshot) {
            final displayName = snapshot.data ?? 
                (friend.nickname.isNotEmpty ? friend.nickname : friend.username);
            return Text(
              displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              friend.username,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            if (friend.phone != null && friend.phone!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                friend.phone!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
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
          // 跳转到好友详情页面
          _showFriendDetail(friend);
        },
      ),
    );
  }

  /// 显示好友详情
  /// 跳转到好友详情页面
  void _showFriendDetail(User friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendDetailPage(friend: friend),
      ),
    ).then((_) {
      // 从好友详情页返回后刷新好友列表
      _loadFriendList();
    });
  }

  /// 设置备注对话框
  void _showRemarkDialog(User friend) async {
    // 先加载当前备注
    final currentRemark = await _remarkService.getRemark(friend.id);
    
    if (!mounted) return;
    
    final remarkController = TextEditingController(text: currentRemark ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置备注'),
        content: TextField(
          controller: remarkController,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: '请输入备注名称',
            border: const OutlineInputBorder(),
            suffixIcon: remarkController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      remarkController.clear();
                    },
                  )
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newRemark = remarkController.text.trim();
              Navigator.of(context).pop();
              
              // 保存备注
              await _remarkService.setRemark(friend.id, newRemark);
              
              // 刷新列表
              if (mounted) {
                setState(() {});
                EasyLoading.showSuccess(newRemark.isEmpty ? '已清除备注' : '备注设置成功');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

