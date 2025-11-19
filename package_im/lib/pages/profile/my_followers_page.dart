import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../friend/friend_detail_page.dart';

/// 我的粉丝页面
class MyFollowersPage extends StatefulWidget {
  const MyFollowersPage({super.key});

  @override
  State<MyFollowersPage> createState() => _MyFollowersPageState();
}

class _MyFollowersPageState extends State<MyFollowersPage> {
  final ApiService _apiService = ApiService();
  List<User> _followersList = [];
  bool _isLoading = false;
  // 记录已关注的用户ID
  Set<int> _followingIds = {};

  @override
  void initState() {
    super.initState();
    _loadFollowersList();
    _loadFollowingList();
  }

  /// 加载粉丝列表
  Future<void> _loadFollowersList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getFollowersList();

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _followersList = response.data!;
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

  /// 加载我的关注列表（用于判断是否已关注）
  Future<void> _loadFollowingList() async {
    try {
      final response = await _apiService.getFollowingList();
      if (mounted && response.success && response.data != null) {
        setState(() {
          _followingIds = response.data!.map((user) => user.id).toSet();
        });
      }
    } catch (e) {
      debugPrint('加载关注列表失败: $e');
    }
  }

  /// 处理关注/取消关注
  Future<void> _handleFollow(User user, bool isFollowing) async {
    try {
      EasyLoading.show(status: '处理中...');
      
      final response = isFollowing
          ? await _apiService.unfollowUser(targetUserId: user.id)
          : await _apiService.followUser(targetUserId: user.id);
      
      EasyLoading.dismiss();

      if (mounted) {
        if (response.success) {
          EasyLoading.showSuccess(isFollowing ? '已取消关注' : '关注成功');
          setState(() {
            if (isFollowing) {
              _followingIds.remove(user.id);
            } else {
              _followingIds.add(user.id);
            }
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

  /// 刷新列表
  Future<void> _onRefresh() async {
    await Future.wait([
      _loadFollowersList(),
      _loadFollowingList(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的粉丝 (${_followersList.length})'),
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

    if (_followersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有粉丝',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '多发布精彩动态吧',
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
      onRefresh: _onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _followersList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = _followersList[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isFollowing = _followingIds.contains(user.id);
    final isMyself = user.id == _apiService.currentUser?.id;

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
                // 关注按钮（不显示给自己）
                if (!isMyself)
                  TextButton(
                    onPressed: () => _handleFollow(user, isFollowing),
                    style: TextButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.grey[200]
                          : Theme.of(context).primaryColor,
                      foregroundColor:
                          isFollowing ? Colors.grey[700] : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isFollowing ? '已关注' : '回关',
                      style: const TextStyle(fontSize: 13),
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

