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
  List<User> _filteredFriendList = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final _apiService = ApiService();
  final _remarkService = RemarkService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriendList();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 搜索变化监听
  void _onSearchChanged() {
    _performSearch(_searchController.text);
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredFriendList = _friendList;
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final results = <User>[];

    for (final friend in _friendList) {
      // 获取备注
      final remark = await _remarkService.getRemark(friend.id);
      
      // 搜索用户名、昵称、备注
      final username = friend.username.toLowerCase();
      final nickname = friend.nickname.toLowerCase();
      final remarkLower = (remark ?? '').toLowerCase();
      
      if (username.contains(queryLower) || 
          nickname.contains(queryLower) || 
          remarkLower.contains(queryLower)) {
        results.add(friend);
      }
    }

    setState(() {
      _filteredFriendList = results;
    });
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
          _filteredFriendList = _friendList;  // 初始化过滤列表
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
      body: Column(
        children: [
          // 渐变美化头部
          _buildBeautifulHeader(context),
          // 主体内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friendList.isEmpty
                    ? _buildEmptyState()
                    : _filteredFriendList.isEmpty
                        ? _buildSearchEmptyState()
                        : _buildFriendList(),
          ),
        ],
      ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddFriend,
              tooltip: '添加好友',
              child: const Icon(Icons.add),
            ),
    );
  }

  /// 构建美化的头部
  Widget _buildBeautifulHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.85),
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // 装饰性圆圈
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // 主要内容
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部标题和按钮行
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      // 大标题
                      const Text(
                        '好友',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // 搜索按钮
                      if (!_isSearching)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSearching = true;
                              });
                            },
                            tooltip: '搜索',
                          ),
                        ),
                      const SizedBox(width: 8),
                      // 添加好友按钮
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _navigateToAddFriend,
                          tooltip: '添加好友',
                        ),
                      ),
                    ],
                  ),
                ),
                // 搜索框（展开时显示）
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '搜索好友名称、账号...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _isSearching = false;
                                _filteredFriendList = _friendList;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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

  /// 搜索无结果状态页面
  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            '未找到相关好友',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '试试其他关键词吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
      child: Column(
        children: [
          // 搜索结果提示
          if (_isSearching && _searchController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '找到 ${_filteredFriendList.length} 个好友',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // 好友列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredFriendList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final friend = _filteredFriendList[index];
                return _buildFriendItem(friend);
              },
            ),
          ),
        ],
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

