import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/video.dart';
import '../../services/api_service.dart';
import 'video_player_widget.dart';
import 'publish_video_page.dart';

/// 短视频页面（抖音风格）
class ShortVideoPage extends StatefulWidget {
  const ShortVideoPage({super.key});

  @override
  State<ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<ShortVideoPage>
    with AutomaticKeepAliveClientMixin {
  final _apiService = ApiService();
  final PreloadPageController _pageController = PreloadPageController();

  List<Video> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 加载视频列表
  Future<void> _loadVideos({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final response = await _apiService.getVideoList(
        page: _currentPage,
        size: 10,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (refresh) {
            _videos = response.data!.videos;
            // 刷新时重置当前索引
            _currentIndex = 0;
          } else {
            _videos.addAll(response.data!.videos);
          }
          _hasMore = response.data!.hasNext;
          _currentPage++;
        });
        
        // 如果是第一次加载且有视频，预加载前3个视频的信息
        if (_videos.isNotEmpty && _currentPage == 1) {
          debugPrint('已加载 ${_videos.length} 个视频，准备播放第一个视频');
        }
      } else {
        if (response.message.isNotEmpty) {
          EasyLoading.showError(response.message);
        }
      }
    } catch (e) {
      debugPrint('加载视频失败: $e');
      EasyLoading.showError('加载失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 点赞视频
  Future<void> _likeVideo(int index) async {
    final video = _videos[index];
    final newLikeStatus = !video.isLiked;

    // 乐观更新 UI
    setState(() {
      _videos[index] = video.copyWith(
        isLiked: newLikeStatus,
        likeCount: video.likeCount + (newLikeStatus ? 1 : -1),
      );
    });

    try {
      final response = await _apiService.likeVideo(
        videoId: video.id,
        like: newLikeStatus,
      );

      if (!response.success) {
        // 如果失败，恢复原状态
        setState(() {
          _videos[index] = video;
        });
        EasyLoading.showError(response.message.isNotEmpty ? response.message : '操作失败');
      }
    } catch (e) {
      // 如果异常，恢复原状态
      setState(() {
        _videos[index] = video;
      });
      EasyLoading.showError('操作失败');
    }
  }

  /// 关注用户
  Future<void> _followUser(int index) async {
    final video = _videos[index];
    final newFollowStatus = !video.isFollowing;

    // 乐观更新 UI
    setState(() {
      _videos[index] = video.copyWith(
        isFollowing: newFollowStatus,
      );
    });

    try {
      final response = await _apiService.followVideoAuthor(
        userId: video.userId,
        follow: newFollowStatus,
      );

      if (!response.success) {
        // 如果失败，恢复原状态
        setState(() {
          _videos[index] = video;
        });
        EasyLoading.showError(response.message.isNotEmpty ? response.message : '操作失败');
      }
    } catch (e) {
      // 如果异常，恢复原状态
      setState(() {
        _videos[index] = video;
      });
      EasyLoading.showError('操作失败');
    }
  }

  /// 分享视频
  Future<void> _shareVideo(int index) async {
    final video = _videos[index];

    try {
      await _apiService.shareVideo(videoId: video.id);
      EasyLoading.showSuccess('分享成功');

      // 更新分享数
      setState(() {
        _videos[index] = video.copyWith(
          shareCount: video.shareCount + 1,
        );
      });
    } catch (e) {
      EasyLoading.showError('分享失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 设置状态栏为透明，图标为浅色
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频列表
          if (_videos.isEmpty)
            _buildEmptyState()
          else
            PreloadPageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              preloadPagesCount: 2, // 预加载前后2页
              itemCount: _videos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });

                // 快到底部时加载更多
                if (index >= _videos.length - 3 && !_isLoading && _hasMore) {
                  _loadVideos();
                }
              },
              itemBuilder: (context, index) {
                return _buildVideoItem(index);
              },
            ),

          // 顶部状态栏区域
          _buildTopBar(),
          
          // 发布按钮
          _buildPublishButton(),
        ],
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildTopBar() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: statusBarHeight + 10,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '推荐',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 视频项
  Widget _buildVideoItem(int index) {
    final video = _videos[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        // 视频播放器
        VideoPlayerWidget(
          video: video,
          isPlaying: index == _currentIndex,
        ),

        // 右侧操作栏
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              // 作者头像和关注按钮
              _buildAvatarWithFollow(video, index),
              const SizedBox(height: 24),
              // 点赞
              _buildActionButton(
                icon: video.isLiked ? Icons.favorite : Icons.favorite_border,
                label: _formatCount(video.likeCount),
                color: video.isLiked ? Colors.red : Colors.white,
                onTap: () => _likeVideo(index),
              ),
              const SizedBox(height: 24),
              // 评论
              _buildActionButton(
                icon: Icons.comment,
                label: _formatCount(video.commentCount),
                onTap: () {
                  // TODO: 打开评论页面
                  EasyLoading.showToast('评论功能开发中');
                },
              ),
              const SizedBox(height: 24),
              // 分享
              _buildActionButton(
                icon: Icons.share,
                label: _formatCount(video.shareCount),
                onTap: () => _shareVideo(index),
              ),
            ],
          ),
        ),

        // 底部信息栏
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户名
              Text(
                '@${video.nickname}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 视频描述
              Text(
                video.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 头像和关注按钮
  Widget _buildAvatarWithFollow(Video video, int index) {
    // 判断是否是当前用户自己的视频
    final isMyVideo = _apiService.currentUser?.id == video.userId;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 头像
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: video.avatarUrl != null
              ? CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: video.avatarUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          video.nickname[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    video.nickname[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        // 关注按钮（如果不是自己的视频且未关注）
        if (!isMyVideo && !video.isFollowing)
          Positioned(
            bottom: -6,
            child: GestureDetector(
              onTap: () => _followUser(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 发布按钮
  Widget _buildPublishButton() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Positioned(
      top: statusBarHeight + 10,
      right: 16,
      child: GestureDetector(
        onTap: () async {
          // 跳转到发布页面
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PublishVideoPage(),
            ),
          );

          // 如果发布成功，刷新视频列表
          if (result == true) {
            _loadVideos(refresh: true);
          }
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  /// 格式化数字
  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _isLoading ? '加载中...' : '暂无视频',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          if (!_isLoading && _videos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () => _loadVideos(refresh: true),
                child: const Text(
                  '点击重试',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

