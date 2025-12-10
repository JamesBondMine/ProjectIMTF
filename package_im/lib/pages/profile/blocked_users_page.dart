import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/blacklist_item.dart';
import '../../services/api_service.dart';
import '../../utils/block_manager.dart';

/// 黑名单管理页面
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({Key? key}) : super(key: key);

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final ApiService _apiService = ApiService();
  final BlockManager _blockManager = BlockManager();
  final ScrollController _scrollController = ScrollController();
  
  List<BlacklistItem> _blockedUsers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  /// 加载黑名单列表
  Future<void> _loadBlockedUsers({bool isRefresh = false}) async {
    // if (_isLoading && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final response = await _apiService.getBlockedUsers(page: _currentPage, size: 10);
      
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _blockedUsers = response.blacklist;
          } else {
            _blockedUsers.addAll(response.blacklist);
          }
          _hasMore = response.hasNext;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        EasyLoading.showError('加载失败: $e');
      }
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final response = await _apiService.getBlockedUsers(page: _currentPage, size: 10);
      
      if (mounted) {
        setState(() {
          _blockedUsers.addAll(response.blacklist);
          _hasMore = response.hasNext;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPage--; // 回退页码
          _isLoadingMore = false;
        });
      }
    }
  }

  /// 解除拉黑
  Future<void> _unblockUser(BlacklistItem item) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解除拉黑'),
        content: Text('确定要解除对 ${item.blockedNickname} 的拉黑吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    EasyLoading.show(status: '处理中...');

    try {
      // 调用 API 解除拉黑
      await _apiService.unblockUser(item.blockedUserId.toString());
      
      // 更新本地黑名单
      await _blockManager.unblockUser(item.blockedUserId.toString());

      // 从列表移除
      setState(() {
        _blockedUsers.removeWhere((u) => u.id == item.id);
      });

      EasyLoading.showSuccess('已解除拉黑');
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('黑名单'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_blockedUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadBlockedUsers(isRefresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _blockedUsers.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _blockedUsers.length) {
            // 加载更多指示器
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : const Text(
                      '加载更多...',
                      style: TextStyle(color: Colors.grey),
                    ),
            );
          }
          final item = _blockedUsers[index];
          return _buildUserItem(item);
        },
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无黑名单',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '被拉黑的用户将无法与你互动',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户项
  Widget _buildUserItem(BlacklistItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: item.blockedAvatarUrl != null && item.blockedAvatarUrl!.isNotEmpty
            ? NetworkImage(item.blockedAvatarUrl!)
            : null,
        child: item.blockedAvatarUrl == null || item.blockedAvatarUrl!.isEmpty
            ? Text(
                item.blockedNickname.isNotEmpty ? item.blockedNickname[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 20),
              )
            : null,
      ),
      title: Text(
        item.blockedNickname,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.blockedUsername.isNotEmpty)
            Text(
              '@${item.blockedUsername}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          if (item.reason != null && item.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '原因：${item.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
      trailing: TextButton(
        onPressed: () => _unblockUser(item),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1,
            ),
          ),
        ),
        child: const Text('解除'),
      ),
    );
  }
}

