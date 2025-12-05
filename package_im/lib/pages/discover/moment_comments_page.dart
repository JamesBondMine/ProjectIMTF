import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/comment.dart';
import '../../models/moment.dart';
import '../../services/api_service.dart';
import '../../utils/collect_manager.dart';

/// 动态评论页面
class MomentCommentsPage extends StatefulWidget {
  final Moment moment;

  const MomentCommentsPage({
    super.key,
    required this.moment,
  });

  @override
  State<MomentCommentsPage> createState() => _MomentCommentsPageState();
}

class _MomentCommentsPageState extends State<MomentCommentsPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<Comment> _comments = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _hasNewComment = false; // 标记是否有新评论
  int? _newCommentId; // 新发表的评论ID
  bool _isCollected = false; // 是否已收藏

  // 回复相关
  Comment? _replyToComment;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
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

  /// 加载评论列表
  Future<void> _loadComments({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final response = await _apiService.getMomentComments(
        momentId: widget.moment.id,
        page: _currentPage,
        size: 20,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final commentListResponse = CommentListResponse.fromJson(response.data);

          setState(() {
            if (isRefresh) {
              _comments = commentListResponse.comments;
            } else {
              _comments.addAll(commentListResponse.comments);
            }
            _hasMore = commentListResponse.hasNext;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          if (!isRefresh) {
            EasyLoading.showError(
                response.message.isNotEmpty ? response.message : '加载失败');
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
      final response = await _apiService.getMomentComments(
        momentId: widget.moment.id,
        page: _currentPage,
        size: 20,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final commentListResponse = CommentListResponse.fromJson(response.data);

          setState(() {
            _comments.addAll(commentListResponse.comments);
            _hasMore = commentListResponse.hasNext;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _currentPage--;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPage--;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _loadComments(isRefresh: true);
  }

  /// 发表评论
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      EasyLoading.showToast('请输入评论内容');
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.postMomentComment(
        momentId: widget.moment.id,
        content: content,
        replyToId: _replyToComment?.id,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          EasyLoading.showSuccess('评论成功');
          
          // 解析返回的评论数据
          final newComment = Comment.fromJson(response.data);
          
          // 将新评论添加到列表顶部
          setState(() {
            _comments.insert(0, newComment);
            _hasNewComment = true; // 标记有新评论
            _newCommentId = newComment.id; // 记录新评论ID
          });
          
          // 3秒后取消高亮
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _newCommentId = null;
              });
            }
          });
          
          // 清空输入框和回复状态
          _commentController.clear();
          _replyToComment = null;
          _commentFocusNode.unfocus();
          
          // 滚动到顶部显示新评论
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else {
          EasyLoading.showError(
              response.message.isNotEmpty ? response.message : '评论失败');
        }
      }
    } catch (e) {
      if (mounted) {
        EasyLoading.showError('评论失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 回复评论
  void _replyComment(Comment comment) {
    setState(() {
      _replyToComment = comment;
    });
    _commentFocusNode.requestFocus();
  }

  /// 取消回复
  void _cancelReply() {
    setState(() {
      _replyToComment = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回时通知上一页是否需要刷新
        Navigator.of(context).pop(_hasNewComment);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('评论 ${_comments.isEmpty ? widget.moment.commentCount : _comments.length}'),
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
        body: Column(
          children: [
            // 动态内容预览
            _buildMomentPreview(),
            Divider(height: 1, color: Colors.grey[300]),
            // 评论列表
            Expanded(
              child: _buildCommentList(),
            ),
            // 评论输入框
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  /// 构建动态预览
  Widget _buildMomentPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              CircleAvatar(
                radius: 20,
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
                        style: const TextStyle(fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 用户名和内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.moment.nickname,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: _parseContentWithTags(widget.moment.content),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 图片展示
          if (widget.moment.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImageGrid(widget.moment.mediaUrls),
          ],
        ],
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
            height: 200,
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

  /// 显示图片查看器
  void _showImageViewer(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildCommentList() {
    if (_isLoading && _comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无评论',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快来发表第一条评论吧',
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
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
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
          return _buildCommentItem(_comments[index]);
        },
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final isNewComment = comment.id == _newCommentId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: isNewComment ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: isNewComment
          ? BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.avatarUrl != null &&
                    comment.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                ? Text(
                    comment.nickname.isNotEmpty ? comment.nickname[0] : '?',
                    style: const TextStyle(fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // 评论内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名
                Text(
                  comment.nickname,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 回复信息（如果是回复）
                if (comment.replyToNickname != null) ...[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: '回复 '),
                        TextSpan(
                          text: '@${comment.replyToNickname}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(text: ': '),
                        TextSpan(text: comment.content),
                      ],
                    ),
                  ),
                ] else
                  // 普通评论
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 8),
                // 时间和回复按钮
                Row(
                  children: [
                    Text(
                      comment.getRelativeTime(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _replyComment(comment),
                      child: Text(
                        '回复',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 回复提示
            if (_replyToComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '回复 @${_replyToComment!.nickname}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _cancelReply,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            // 输入框
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        decoration: const InputDecoration(
                          hintText: '说点什么...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _isSubmitting ? null : _submitComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSubmitting
                            ? Colors.grey[400]
                            : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
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
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ));
      }
      
      // 添加高亮的标签（包含空格）
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).primaryColor,
          height: 1.4,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // 添加剩余的普通文本
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.4,
        ),
      ));
    }
    
    return spans;
  }
}

/// 图片查看器页面
class ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
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
                    const SizedBox(width: 48), // 占位，保持居中
                  ],
                ),
              ),
            ),
          ),
          
          // 底部指示器（可选）
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
