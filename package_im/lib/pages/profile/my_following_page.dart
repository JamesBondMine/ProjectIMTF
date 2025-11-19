import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../friend/friend_detail_page.dart';

/// 我的关注页面
class MyFollowingPage extends StatefulWidget {
  const MyFollowingPage({super.key});

  @override
  State<MyFollowingPage> createState() => _MyFollowingPageState();
}

class _MyFollowingPageState extends State<MyFollowingPage> {
  final ApiService _apiService = ApiService();
  List<User> _followingList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFollowingList();
  }

  /// 加载关注列表
  Future<void> _loadFollowingList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getFollowingList();

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _followingList = response.data!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          EasyLoading.showError(
              response.message.isNotEmpty ? response.message : '加载失败');
        }
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

  /// 处理取消关注
  Future<void> _handleUnfollow(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消关注'),
        content: Text('确定要取消关注 ${user.nickname} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      EasyLoading.show(status: '处理中...');
      final response = await _apiService.unfollowUser(targetUserId: user.id);
      EasyLoading.dismiss();

      if (mounted) {
        if (response.success) {
          EasyLoading.showSuccess('已取消关注');
          // 从列表中移除
          setState(() {
            _followingList.removeWhere((u) => u.id == user.id);
          });
        } else {
          EasyLoading.showError(
              response.message.isNotEmpty ? response.message : '操作失败');
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        EasyLoading.showError('操作失败: $e');
      }
    }
  }

  /// 跳转到用户详情页
  void _navigateToUserDetail(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendDetailPage(friend: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的关注 (${_followingList.length})'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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

    if (_followingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有关注任何人',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快去发现页面关注感兴趣的人吧',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowingList,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _followingList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = _followingList[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToUserDetail(user),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: user.avatarUrl != null &&
                          user.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          user.nickname.isNotEmpty
                              ? user.nickname[0].toUpperCase()
                              : user.username[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // 用户信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 取消关注按钮
                TextButton(
                  onPressed: () => _handleUnfollow(user),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[700],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '已关注',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

