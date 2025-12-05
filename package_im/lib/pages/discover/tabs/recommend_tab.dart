import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../models/moment.dart';
import '../../../models/user.dart';
import '../../../services/api_service.dart';
import '../moment_comments_page.dart';
import '../../friend/friend_detail_page.dart';

/// 推荐页签
class RecommendTab extends StatefulWidget {
  const RecommendTab({super.key});

  @override
  State<RecommendTab> createState() => RecommendTabState();
}

class RecommendTabState extends State<RecommendTab> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  List<Moment> _moments = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  /// 跳转到用户详情页面
  void _navigateToUserDetail(Moment moment) {
    // 将 Moment 的用户信息转换为 User 对象
    final user = User(
      id: moment.userId,
      username: moment.username,
      nickname: moment.nickname,
      email: '',
      avatarUrl: moment.avatarUrl,
      userType: 'NORMAL',
      status: 'ACTIVE',
      isGuest: false,
      createdAt: moment.createdAt.toIso8601String(),
      updatedAt: moment.updatedAt.toIso8601String(),
      isFriend: moment.isFriend,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendDetailPage(friend: user),
      ),
    );
  }

  /// 处理关注/取消关注
  Future<void> _handleFollow(Moment moment) async {
    // 乐观更新UI
    final index = _moments.indexWhere((m) => m.id == moment.id);
    if (index == -1) return;

    final originalMoment = _moments[index];
    final newFollowingState = !originalMoment.isFollowing;

    setState(() {
      _moments[index] = originalMoment.copyWith(
        isFollowing: newFollowingState,
      );
    });

    try {
      final response = newFollowingState
          ? await _apiService.followUser(targetUserId: moment.userId)
          : await _apiService.unfollowUser(targetUserId: moment.userId);

      if (mounted) {
        if (response.success) {
          EasyLoading.showSuccess(newFollowingState ? '关注成功' : '取消关注成功');
        } else {
          // 关注/取消关注失败，恢复原状态
          setState(() {
            _moments[index] = originalMoment;
          });
          EasyLoading.showError(response.message.isNotEmpty 
              ? response.message 
              : (newFollowingState ? '关注失败' : '取消关注失败'));
        }
      }
    } catch (e) {
      if (mounted) {
        // 发生异常，恢复原状态
        setState(() {
          _moments[index] = originalMoment;
        });
        EasyLoading.showError('操作失败: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadMoments();
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

  /// 加载动态列表（公开方法，供外部刷新）
  Future<void> loadMoments({bool isRefresh = false}) async {
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
    await loadMoments(isRefresh: true);
  }

  /// 处理点赞/取消点赞
  Future<void> _handleLike(Moment moment) async {
    final index = _moments.indexWhere((m) => m.id == moment.id);
    if (index == -1) return;

    // 乐观更新UI
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
      child: MasonryGridView.count(
        controller: _scrollController,
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.all(8),
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
          return _buildWaterfallCard(_moments[index]);
        },
      ),
    );
  }

  /// 瀑布流卡片样式
  Widget _buildWaterfallCard(Moment moment) {
    return GestureDetector(
      onTap: () => _navigateToComments(moment),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片（只显示第一张）
            if (moment.mediaUrls.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: moment.mediaUrls[0],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 如果有多张图，显示数量角标
                  if (moment.mediaUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${moment.mediaUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 内容（最多3行，标签高亮）
                  RichText(
                    text: TextSpan(
                      children: _parseContentWithTags(moment.content),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  
                  // 用户信息
                  GestureDetector(
                    onTap: () => _navigateToUserDetail(moment),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: moment.avatarUrl != null && moment.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(moment.avatarUrl!)
                              : null,
                          child: moment.avatarUrl == null || moment.avatarUrl!.isEmpty
                              ? Text(
                                  moment.nickname.isNotEmpty ? moment.nickname[0] : '?',
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            moment.nickname,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 关注按钮
                        if (!moment.isMyMoment)
                          GestureDetector(
                            onTap: () => _handleFollow(moment),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: moment.isFollowing 
                                    ? Colors.grey[200] 
                                    : Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                moment.isFollowing ? '已关注' : '+关注',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: moment.isFollowing 
                                      ? Colors.grey[700] 
                                      : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // 互动数据
                  Row(
                    children: [
                      // 点赞按钮（可点击）
                      GestureDetector(
                        onTap: () => _handleLike(moment),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              moment.liked ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: moment.liked ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${moment.likeCount}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${moment.commentCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      loadMoments(isRefresh: true);
    }
  }

  /// 解析内容中的标签并高亮显示
  /// 标签格式：#标签名 （以空格结尾）
  List<TextSpan> _parseContentWithTags(String content) {
    final List<TextSpan> spans = [];
    // 匹配 #开头 空格结尾 的标签
    final tagRegex = RegExp(r'#[^\s]+\s');
    
    int lastIndex = 0;
    for (final match in tagRegex.allMatches(content)) {
      // 添加标签前的普通文本
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.black87,
          ),
        ));
      }
      
      // 添加高亮的标签（包含空格）
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // 添加剩余的普通文本
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Colors.black87,
        ),
      ));
    }
    
    return spans;
  }
}

