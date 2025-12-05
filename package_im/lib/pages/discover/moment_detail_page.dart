import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/moment.dart';
import '../../utils/collect_manager.dart';

/// 动态详情页面（只展示图文，不展示评论）
class MomentDetailPage extends StatefulWidget {
  final Moment moment;
  final VoidCallback? onUncollect; // 取消收藏回调

  const MomentDetailPage({
    super.key,
    required this.moment,
    this.onUncollect,
  });

  @override
  State<MomentDetailPage> createState() => _MomentDetailPageState();
}

class _MomentDetailPageState extends State<MomentDetailPage> {
  late bool _isCollected;

  @override
  void initState() {
    super.initState();
    _checkCollectStatus();
  }

  /// 检查收藏状态
  Future<void> _checkCollectStatus() async {
    final isCollected = await CollectManager.isCollected(widget.moment.id);
    if (mounted) {
      setState(() {
        _isCollected = isCollected;
      });
    }
  }

  /// 处理收藏/取消收藏
  Future<void> _toggleCollect() async {
    try {
      if (_isCollected) {
        // 取消收藏
        final success = await CollectManager.uncollectMoment(widget.moment.id);
        if (success) {
          setState(() {
            _isCollected = false;
          });
          EasyLoading.showSuccess('已取消收藏');
          // 通知上一页刷新
          widget.onUncollect?.call();
        }
      } else {
        // 收藏
        final success = await CollectManager.collectMoment(widget.moment);
        if (success) {
          setState(() {
            _isCollected = true;
          });
          EasyLoading.showSuccess('收藏成功');
        } else {
          EasyLoading.showToast('已经收藏过了');
        }
      }
    } catch (e) {
      EasyLoading.showError('操作失败');
    }
  }

  /// 显示图片查看器
  void _showImageViewer(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewerPage(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态详情'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // 收藏按钮
          IconButton(
            onPressed: _toggleCollect,
            icon: Icon(
              _isCollected ? Icons.bookmark : Icons.bookmark_border,
              size: 26,
            ),
            tooltip: _isCollected ? '取消收藏' : '收藏',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 头像
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.moment.avatarUrl != null &&
                            widget.moment.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.moment.avatarUrl!)
                        : null,
                    child: widget.moment.avatarUrl == null ||
                            widget.moment.avatarUrl!.isEmpty
                        ? Text(
                            widget.moment.nickname.isNotEmpty
                                ? widget.moment.nickname[0]
                                : '?',
                            style: const TextStyle(fontSize: 20),
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
                          widget.moment.nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.moment.getRelativeTime(),
                          style: TextStyle(
                            fontSize: 13,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  children: _parseContentWithTags(widget.moment.content),
                ),
              ),
            ),
            
            // 图片展示
            if (widget.moment.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildImageGrid(widget.moment.mediaUrls),
              ),
            ],
            
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[300]),
            
            // 互动数据
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.moment.liked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: widget.moment.liked ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.moment.likeCount}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.moment.commentCount}',
                    style: TextStyle(
                      fontSize: 15,
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

  /// 构建图片网格
  Widget _buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    // 单张图片
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _showImageViewer(images, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: images[0],
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 多张图片 - 3列网格
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
        return GestureDetector(
          onTap: () => _showImageViewer(images, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
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
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ));
      }
      
      // 添加高亮的标签（包含空格）
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
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
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ));
    }
    
    return spans;
  }
}

/// 图片查看器页面
class _ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageViewerPage({
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片画廊
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(widget.images[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.images[index]),
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          
          // 顶部栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      '${_currentIndex + 1}/${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          
          // 底部指示器
          if (widget.images.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length > 10 ? 10 : widget.images.length,
                  (index) {
                    if (index == 9 && widget.images.length > 10) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        child: const Text(
                          '...',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

