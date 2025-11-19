import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/video.dart';

/// 短视频播放器组件
class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final bool isPlaying;
  final VoidCallback? onTap;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.isPlaying,
    this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果视频变化，重新初始化
    if (widget.video.id != oldWidget.video.id) {
      _disposeControllers();
      _initializeVideo();
      return;
    }
    
    // 根据播放状态控制视频
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (_videoController != null && _isInitialized) {
        if (widget.isPlaying) {
          _videoController!.play();
        } else {
          _videoController!.pause();
        }
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isInitialized = false;
        _hasError = false;
        _errorMessage = null;
        _isBuffering = true;
      });

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // 允许与其他音频混合
          allowBackgroundPlayback: false,
        ),
      );

      // 监听缓冲状态
      _videoController!.addListener(_videoListener);

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.isPlaying,
        looping: true,
        showControls: false, // 抖音风格，隐藏控制条
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: widget.video.coverUrl != null
            ? Image.network(
                widget.video.coverUrl!,
                fit: BoxFit.cover,
              )
            : null,
      );

      // 如果需要播放，先预加载视频
      if (widget.isPlaying) {
        // 静音预加载，让视频开始缓冲
        await _videoController!.setVolume(0);
        await _videoController!.play();
        // 等待一小段时间让视频缓冲
        await Future.delayed(const Duration(milliseconds: 100));
        // 恢复音量
        await _videoController!.setVolume(1.0);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isBuffering = false;
        });
      }
    } catch (e) {
      debugPrint('初始化视频失败: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '视频加载失败';
          _isBuffering = false;
        });
      }
    }
  }

  /// 视频状态监听器
  void _videoListener() {
    if (_videoController == null) return;
    
    final isBuffering = _videoController!.value.isBuffering;
    if (_isBuffering != isBuffering && mounted) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }
  }

  void _disposeControllers() {
    _videoController?.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击暂停/播放
        if (_videoController != null && _isInitialized) {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        }
        widget.onTap?.call();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频播放器
            if (_isInitialized && _chewieController != null)
              Center(
                child: Chewie(controller: _chewieController!),
              )
            else if (_hasError)
              _buildErrorWidget()
            else
              _buildLoadingWidget(),

            // 缓冲指示器
            if (_isInitialized && _isBuffering)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '缓冲中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 暂停图标
            if (_isInitialized &&
                _videoController != null &&
                !_videoController!.value.isPlaying &&
                !_isBuffering)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 加载中组件
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '加载中...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 错误组件
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '视频加载失败',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeVideo,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

