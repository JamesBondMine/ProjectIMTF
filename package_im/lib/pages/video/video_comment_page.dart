import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comment.dart';
import '../../services/api_service.dart';

/// 视频评论页面（底部弹窗）
class VideoCommentPage extends StatefulWidget {
  final int videoId;
  final int initialCommentCount;

  const VideoCommentPage({
    super.key,
    required this.videoId,
    required this.initialCommentCount,
  });

  @override
  State<VideoCommentPage> createState() => _VideoCommentPageState();
}

class _VideoCommentPageState extends State<VideoCommentPage> {
  final _apiService = ApiService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isPosting = false;
  bool _isLoadingMore = false;
  int _commentCount = 0;
  int _currentPage = 0;
  bool _hasMore = true;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;
    _scrollController.addListener(_onScroll);
    _loadComments();
  }
  
  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200px时加载更多
      if (!_isLoadingMore && _hasMore) {
        _loadMoreComments();
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载评论列表（首次）
  Future<void> _loadComments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    try {
      final response = await _apiService.getVideoComments(
        videoId: widget.videoId,
        page: 0,
        size: 20,
      );

      if (response.success && response.data != null) {
        final commentResponse = CommentListResponse.fromJson(response.data!);
        
        setState(() {
          _comments = commentResponse.comments;
          _commentCount = commentResponse.totalElements;
          _totalElements = commentResponse.totalElements;
          _currentPage = commentResponse.currentPage;
          _hasMore = commentResponse.hasNext;
        });
        
        debugPrint('评论加载完成: 总数=$_totalElements, 当前页=$_currentPage, 本页${_comments.length}条, 还有更多=$_hasMore');
      }
    } catch (e) {
      debugPrint('加载评论失败: $e');
      EasyLoading.showError('加载评论失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载更多评论
  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      debugPrint('加载更多评论: page=$nextPage');
      
      final response = await _apiService.getVideoComments(
        videoId: widget.videoId,
        page: nextPage,
        size: 20,
      );

      if (response.success && response.data != null) {
        final commentResponse = CommentListResponse.fromJson(response.data!);
        
        setState(() {
          _comments.addAll(commentResponse.comments);
          _currentPage = commentResponse.currentPage;
          _hasMore = commentResponse.hasNext;
        });
        
        debugPrint('加载更多完成: 当前页=$_currentPage, 新增${commentResponse.comments.length}条, 还有更多=$_hasMore');
      }
    } catch (e) {
      debugPrint('加载更多评论失败: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// 发表评论
  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    
    if (content.isEmpty) {
      EasyLoading.showToast('请输入评论内容');
      return;
    }

    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final response = await _apiService.postVideoComment(
        videoId: widget.videoId,
        content: content,
      );

      if (response.success && response.data != null) {
        // 添加新评论到列表顶部
        final newComment = Comment.fromJson(response.data!);
        setState(() {
          _comments.insert(0, newComment);
          _commentCount = _comments.length;
          _commentController.clear();
        });
        
        EasyLoading.showSuccess('评论成功');
        
        // 滚动到顶部
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        EasyLoading.showError(response.message.isNotEmpty ? response.message : '评论失败');
      }
    } catch (e) {
      debugPrint('发表评论失败: $e');
      EasyLoading.showError('评论失败');
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(),
          
          const Divider(height: 1),
          
          // 评论列表
          Expanded(
            child: _isLoading && _comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : _buildCommentList(),
          ),
          
          const Divider(height: 1),
          
          // 输入框
          _buildInputBar(),
        ],
      ),
    );
  }

  /// 标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '$_commentCount条评论',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _commentCount),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 评论列表
  Widget _buildCommentList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 评论项
        if (index < _comments.length) {
          return _buildCommentItem(_comments[index]);
        }
        
        // 加载更多指示器
        return _buildLoadingMoreIndicator();
      },
    );
  }
  
  /// 加载更多指示器
  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '加载中...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          : Text(
              '下拉加载更多',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
    );
  }

  /// 评论项
  Widget _buildCommentItem(Comment comment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            child: comment.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: comment.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Text(
                        comment.nickname[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    comment.nickname[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // 评论文本
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[900],
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // 时间
                Text(
                  _formatTime(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有评论',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快来发表第一条评论吧~',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 输入栏
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _postComment(),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 发送按钮
          GestureDetector(
            onTap: _isPosting ? null : _postComment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isPosting
                    ? Colors.grey[300]
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '发送',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}-${time.day}';
    }
  }
}

