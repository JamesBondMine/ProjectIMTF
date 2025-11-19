import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/moment.dart';
import '../../services/api_service.dart';
import 'publish_moment_page.dart';
import 'moment_comments_page.dart';

/// 发现页面
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_RecommendTabState> _recommendTabKey = GlobalKey<_RecommendTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              toolbarHeight: 48,
              flexibleSpace: SafeArea(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: '推荐'),
                    Tab(text: '关注'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _RecommendTab(key: _recommendTabKey),
            const _FollowTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showPublishOptions(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  /// 显示发布选项
  void _showPublishOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPublishOption(
                  icon: Icons.image_outlined,
                  title: '发布图文',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(context);
                    // 跳转到发布图文页面
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const PublishMomentPage(),
                      ),
                    );
                    
                    // 如果发布成功，刷新推荐列表
                    if (result == true && mounted) {
                      _recommendTabKey.currentState?._loadMoments(isRefresh: true);
                    }
                  },
                ),
                _buildPublishOption(
                  icon: Icons.videocam_outlined,
                  title: '发布视频',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转到发布视频页面
                  },
                ),
                _buildPublishOption(
                  icon: Icons.article_outlined,
                  title: '发布文章',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转到发布文章页面
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublishOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

/// 推荐页签
class _RecommendTab extends StatefulWidget {
  const _RecommendTab({super.key});

  @override
  State<_RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<_RecommendTab> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  List<Moment> _moments = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMoments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听，触发加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  /// 加载动态列表
  Future<void> _loadMoments({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final response = await _apiService.getMoments(
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final momentListResponse = MomentListResponse.fromJson(response.data);
          
          setState(() {
            if (isRefresh) {
              _moments = momentListResponse.moments;
            } else {
              _moments.addAll(momentListResponse.moments);
            }
            _hasMore = momentListResponse.hasNext;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (!isRefresh) {
            EasyLoading.showError(response.message.isNotEmpty 
                ? response.message 
                : '加载失败');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (!isRefresh) {
          EasyLoading.showError('加载失败: $e');
        }
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
      final response = await _apiService.getMoments(
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final momentListResponse = MomentListResponse.fromJson(response.data);
          
          setState(() {
            _moments.addAll(momentListResponse.moments);
            _hasMore = momentListResponse.hasNext;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _currentPage--; // 回退页码
            _isLoadingMore = false;
          });
        }
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

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _loadMoments(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _moments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_moments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无动态',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _moments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _moments.length) {
            // 加载更多指示器
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '加载更多...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
            );
          }
          return _buildPostCard(_moments[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(Moment moment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息
          Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 22,
                backgroundImage: moment.avatarUrl != null && moment.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(moment.avatarUrl!)
                    : null,
                child: moment.avatarUrl == null || moment.avatarUrl!.isEmpty
                    ? Text(
                        moment.nickname.isNotEmpty ? moment.nickname[0] : '?',
                        style: const TextStyle(fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 用户名和时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moment.getRelativeTime(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 关注按钮（仅非好友显示）
              if (!moment.isFriend)
                TextButton(
                  onPressed: () {
                    // TODO: 关注功能
                    EasyLoading.showToast('关注功能开发中');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '关注',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 内容
          Text(
            moment.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (moment.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 图片
            _buildImageGrid(moment.mediaUrls),
          ],
          const SizedBox(height: 12),
          // 互动按钮
          Row(
            children: [
              _buildActionButton(
                icon: moment.liked ? Icons.favorite : Icons.favorite_border,
                label: '${moment.likeCount}',
                color: moment.liked ? Colors.red : Colors.grey[600],
                onTap: () => _handleLike(moment),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${moment.commentCount}',
                color: Colors.grey[600],
                onTap: () => _navigateToComments(moment),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: '分享',
                color: Colors.grey[600],
                onTap: () {
                  // TODO: 分享
                  EasyLoading.showToast('分享功能开发中');
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  // TODO: 更多选项
                  EasyLoading.showToast('更多选项开发中');
                },
                color: Colors.grey[600],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理点赞/取消点赞
  Future<void> _handleLike(Moment moment) async {
    // 乐观更新UI
    final index = _moments.indexWhere((m) => m.id == moment.id);
    if (index == -1) return;

    final updatedMoment = moment.copyWith(
      liked: !moment.liked,
      likeCount: moment.liked ? moment.likeCount - 1 : moment.likeCount + 1,
    );

    setState(() {
      _moments[index] = updatedMoment;
    });

    try {
      // 调用API
      if (updatedMoment.liked) {
        await _apiService.likeMoment(moment.id);
      } else {
        await _apiService.unlikeMoment(moment.id);
      }
    } catch (e) {
      // 失败时回滚
      setState(() {
        _moments[index] = moment;
      });
      EasyLoading.showError('操作失败');
    }
  }

  /// 跳转到评论页面
  Future<void> _navigateToComments(Moment moment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MomentCommentsPage(moment: moment),
      ),
    );

    // 如果发表了评论，刷新当前动态
    if (result == true && mounted) {
      // TODO: 可以选择刷新整个列表或只更新该动态的评论数
      _loadMoments(isRefresh: true);
    }
  }

  Widget _buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: images[0],
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length > 9 ? 9 : images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 关注页签
class _FollowTab extends StatefulWidget {
  const _FollowTab();

  @override
  State<_FollowTab> createState() => _FollowTabState();
}

class _FollowTabState extends State<_FollowTab> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  List<Moment> _moments = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMoments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听，触发加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  /// 加载关注的动态列表
  Future<void> _loadMoments({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final response = await _apiService.getFollowingMoments(
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final momentListResponse = MomentListResponse.fromJson(response.data);
          
          setState(() {
            if (isRefresh) {
              _moments = momentListResponse.moments;
            } else {
              _moments.addAll(momentListResponse.moments);
            }
            _hasMore = momentListResponse.hasNext;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (!isRefresh) {
            EasyLoading.showError(response.message.isNotEmpty 
                ? response.message 
                : '加载失败');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (!isRefresh) {
          EasyLoading.showError('加载失败: $e');
        }
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
      final response = await _apiService.getFollowingMoments(
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final momentListResponse = MomentListResponse.fromJson(response.data);
          
          setState(() {
            _moments.addAll(momentListResponse.moments);
            _hasMore = momentListResponse.hasNext;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _currentPage--; // 回退页码
            _isLoadingMore = false;
          });
        }
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

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _loadMoments(isRefresh: true);
  }

  /// 处理点赞/取消点赞
  Future<void> _handleLike(Moment moment) async {
    final index = _moments.indexWhere((m) => m.id == moment.id);
    if (index == -1) return;

    final updatedMoment = moment.copyWith(
      liked: !moment.liked,
      likeCount: moment.liked ? moment.likeCount - 1 : moment.likeCount + 1,
    );

    setState(() {
      _moments[index] = updatedMoment;
    });

    try {
      // 调用API
      if (updatedMoment.liked) {
        await _apiService.likeMoment(moment.id);
      } else {
        await _apiService.unlikeMoment(moment.id);
      }
    } catch (e) {
      // 失败时回滚
      setState(() {
        _moments[index] = moment;
      });
      EasyLoading.showError('操作失败');
    }
  }

  /// 跳转到评论页面
  Future<void> _navigateToComments(Moment moment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MomentCommentsPage(moment: moment),
      ),
    );

    // 如果发表了评论，刷新当前动态
    if (result == true && mounted) {
      _loadMoments(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _moments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_moments.isEmpty) {
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
              '暂无关注的人的动态',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快去关注一些朋友吧',
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
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _moments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _moments.length) {
            // 加载更多指示器
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '加载更多...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
            );
          }
          return _buildPostCard(_moments[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(Moment moment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息
          Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 22,
                backgroundImage: moment.avatarUrl != null && moment.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(moment.avatarUrl!)
                    : null,
                child: moment.avatarUrl == null || moment.avatarUrl!.isEmpty
                    ? Text(
                        moment.nickname.isNotEmpty ? moment.nickname[0] : '?',
                        style: const TextStyle(fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 用户名和时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moment.getRelativeTime(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  // TODO: 更多选项
                  EasyLoading.showToast('更多选项开发中');
                },
                color: Colors.grey[600],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 内容
          Text(
            moment.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (moment.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 图片
            _buildImageGrid(moment.mediaUrls),
          ],
          const SizedBox(height: 12),
          // 互动按钮
          Row(
            children: [
              _buildActionButton(
                icon: moment.liked ? Icons.favorite : Icons.favorite_border,
                label: '${moment.likeCount}',
                color: moment.liked ? Colors.red : Colors.grey[600],
                onTap: () => _handleLike(moment),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${moment.commentCount}',
                color: Colors.grey[600],
                onTap: () => _navigateToComments(moment),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: '分享',
                color: Colors.grey[600],
                onTap: () {
                  // TODO: 分享
                  EasyLoading.showToast('分享功能开发中');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: images[0],
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length > 9 ? 9 : images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


