import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 发现页面
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
              title: const Text(
                '发现',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    // TODO: 搜索功能
                  },
                ),
              ],
              bottom: TabBar(
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            _RecommendTab(),
            _FollowTab(),
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
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 跳转到发布图文页面
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
  const _RecommendTab();

  @override
  State<_RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<_RecommendTab> {
  // 模拟动态数据
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'user': {
        'name': '旅行达人小李',
        'avatar': 'https://picsum.photos/200/200?random=1',
      },
      'content': '今天去了一个超美的地方，风景如画！分享给大家～',
      'images': [
        'https://picsum.photos/400/300?random=11',
        'https://picsum.photos/400/300?random=12',
        'https://picsum.photos/400/300?random=13',
      ],
      'likes': 128,
      'comments': 23,
      'isLiked': false,
      'isFollowed': false,
      'time': '2小时前',
    },
    {
      'id': 2,
      'user': {
        'name': '美食探索者',
        'avatar': 'https://picsum.photos/200/200?random=2',
      },
      'content': '今日份的下午茶☕️ 这家店的蛋糕真的太好吃了！',
      'images': [
        'https://picsum.photos/400/300?random=21',
      ],
      'likes': 256,
      'comments': 45,
      'isLiked': true,
      'isFollowed': true,
      'time': '5小时前',
    },
    {
      'id': 3,
      'user': {
        'name': '科技数码君',
        'avatar': 'https://picsum.photos/200/200?random=3',
      },
      'content': '新入手的这款产品体验真不错，给大家测评一下～',
      'images': [
        'https://picsum.photos/400/300?random=31',
        'https://picsum.photos/400/300?random=32',
      ],
      'likes': 89,
      'comments': 12,
      'isLiked': false,
      'isFollowed': false,
      'time': '8小时前',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // 刷新数据
      });
    }
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
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
                backgroundImage: CachedNetworkImageProvider(post['user']['avatar']),
              ),
              const SizedBox(width: 12),
              // 用户名和时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user']['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post['time'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 关注按钮
              TextButton(
                onPressed: () {
                  setState(() {
                    post['isFollowed'] = !post['isFollowed'];
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: post['isFollowed']
                      ? Colors.grey[200]
                      : Theme.of(context).primaryColor,
                  foregroundColor: post['isFollowed'] ? Colors.grey[700] : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  post['isFollowed'] ? '已关注' : '关注',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 内容
          Text(
            post['content'],
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // 图片
          _buildImageGrid(post['images']),
          const SizedBox(height: 12),
          // 互动按钮
          Row(
            children: [
              _buildActionButton(
                icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                label: '${post['likes']}',
                color: post['isLiked'] ? Colors.red : Colors.grey[600],
                onTap: () {
                  setState(() {
                    post['isLiked'] = !post['isLiked'];
                    post['likes'] += post['isLiked'] ? 1 : -1;
                  });
                },
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post['comments']}',
                color: Colors.grey[600],
                onTap: () {
                  // TODO: 查看评论
                },
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: '分享',
                color: Colors.grey[600],
                onTap: () {
                  // TODO: 分享
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  // TODO: 更多选项
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
  // 模拟关注列表数据
  final List<Map<String, dynamic>> _followedUsers = [
    {
      'id': 1,
      'name': '张三',
      'avatar': 'https://picsum.photos/200/200?random=101',
      'bio': '热爱生活，热爱摄影',
      'postCount': 128,
    },
    {
      'id': 2,
      'name': '李四',
      'avatar': 'https://picsum.photos/200/200?random=102',
      'bio': '美食博主 | 探店达人',
      'postCount': 256,
    },
    {
      'id': 3,
      'name': '王五',
      'avatar': 'https://picsum.photos/200/200?random=103',
      'bio': '科技数码爱好者',
      'postCount': 89,
    },
  ];

  // 模拟关注的人的动态
  final List<Map<String, dynamic>> _followedPosts = [
    {
      'id': 1,
      'user': {
        'name': '张三',
        'avatar': 'https://picsum.photos/200/200?random=101',
      },
      'content': '今天天气真好，出来散散步～',
      'images': [
        'https://picsum.photos/400/300?random=51',
      ],
      'likes': 45,
      'comments': 8,
      'isLiked': false,
      'time': '1小时前',
    },
    {
      'id': 2,
      'user': {
        'name': '李四',
        'avatar': 'https://picsum.photos/200/200?random=102',
      },
      'content': '新发现的宝藏餐厅，味道超赞！',
      'images': [
        'https://picsum.photos/400/300?random=52',
        'https://picsum.photos/400/300?random=53',
      ],
      'likes': 67,
      'comments': 12,
      'isLiked': true,
      'time': '3小时前',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 关注的人列表
          _buildFollowedUsersSection(),
          const SizedBox(height: 8),
          // 关注的人的动态
          _buildFollowedPostsSection(),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // 刷新数据
      });
    }
  }

  Widget _buildFollowedUsersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '我的关注',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 查看全部关注
                },
                child: Text(
                  '查看全部 ${_followedUsers.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _followedUsers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final user = _followedUsers[index];
                return _buildFollowedUserCard(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowedUserCard(Map<String, dynamic> user) {
    return Container(
      width: 80,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: CachedNetworkImageProvider(user['avatar']),
          ),
          const SizedBox(height: 8),
          Text(
            user['name'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowedPostsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '最新动态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _followedPosts.length,
            itemBuilder: (context, index) {
              return _buildFollowedPostCard(_followedPosts[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowedPostCard(Map<String, dynamic> post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(post['user']['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user']['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      post['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
                color: Colors.grey[600],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 内容
          Text(
            post['content'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if ((post['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPostImages(post['images']),
          ],
          const SizedBox(height: 12),
          // 互动按钮
          Row(
            children: [
              _buildActionButton(
                icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                label: '${post['likes']}',
                color: post['isLiked'] ? Colors.red : Colors.grey[600],
                onTap: () {
                  setState(() {
                    post['isLiked'] = !post['isLiked'];
                    post['likes'] += post['isLiked'] ? 1 : -1;
                  });
                },
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post['comments']}',
                color: Colors.grey[600],
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostImages(List<String> images) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: images[0],
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: images.length,
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
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

