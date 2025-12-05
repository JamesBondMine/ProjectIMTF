import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/moment.dart';
import '../../../services/api_service.dart';
import '../../../utils/collect_manager.dart';
import '../moment_detail_page.dart';

/// 收藏页签
class CollectTab extends StatefulWidget {
  const CollectTab({super.key});

  @override
  State<CollectTab> createState() => _CollectTabState();
}

class _CollectTabState extends State<CollectTab> {
  final ScrollController _scrollController = ScrollController();
  
  List<Moment> _moments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 从本地加载收藏的动态列表
  Future<void> _loadMoments({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 从本地加载收藏的动态
      final collected = await CollectManager.getCollectedMoments();
      
      if (mounted) {
        setState(() {
          _moments = collected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('加载收藏失败: $e');
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
      final ApiService apiService = ApiService();
      if (updatedMoment.liked) {
        await apiService.likeMoment(moment.id);
      } else {
        await apiService.unlikeMoment(moment.id);
      }
    } catch (e) {
      // 失败时回滚
      setState(() {
        _moments[index] = moment;
      });
      debugPrint('点赞失败: $e');
    }
  }

  /// 跳转到详情页面（不展示评论）
  Future<void> _navigateToDetail(Moment moment) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MomentDetailPage(
          moment: moment,
          onUncollect: () {
            // 刷新列表
            _loadMoments(isRefresh: true);
          },
        ),
      ),
    );
    // 返回后刷新，因为可能取消了收藏
    _loadMoments(isRefresh: true);
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
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无收藏',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快去收藏喜欢的内容吧',
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
        itemCount: _moments.length,
        itemBuilder: (context, index) {
          return _buildListCard(_moments[index]);
        },
      ),
    );
  }

  /// 列表卡片样式
  Widget _buildListCard(Moment moment) {
    return GestureDetector(
      onTap: () => _navigateToDetail(moment),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            // 用户信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: moment.avatarUrl != null && moment.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(moment.avatarUrl!)
                        : null,
                    child: moment.avatarUrl == null || moment.avatarUrl!.isEmpty
                        ? Text(
                            moment.nickname.isNotEmpty ? moment.nickname[0] : '?',
                            style: const TextStyle(fontSize: 16),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.nickname,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          moment.getRelativeTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 内容文字（标签高亮）
            if (moment.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: RichText(
                  text: TextSpan(
                    children: _parseContentWithTags(moment.content),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            // 图片展示
            if (moment.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildImagePreview(moment.mediaUrls),
              ),
            ],
            
            // 互动数据
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 点赞按钮（可点击）
                  GestureDetector(
                    onTap: () => _handleLike(moment),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          moment.liked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: moment.liked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${moment.likeCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${moment.commentCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片预览
  Widget _buildImagePreview(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    // 单张图片
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: images[0],
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    // 多张图片 - 显示3列网格
    final displayCount = images.length > 9 ? 9 : images.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
              ),
              // 如果有更多图片，在最后一张上显示数量
              if (images.length > 9 && index == 8)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  alignment: Alignment.center,
                  child: Text(
                    '+${images.length - 9}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
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
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ));
      }
      
      // 添加高亮的标签（包含空格）
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
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
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ));
    }
    
    return spans;
  }
}

