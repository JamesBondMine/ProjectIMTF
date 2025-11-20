import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// 视频缓存管理器
/// 用于管理视频播放器的预加载和缓存
class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._internal();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();

  // 缓存的视频控制器
  final Map<String, VideoPlayerController> _cachedControllers = {};
  
  // 最大缓存数量
  static const int maxCacheSize = 5;

  /// 预初始化视频
  Future<VideoPlayerController?> preloadVideo(String videoUrl) async {
    // 如果已经缓存，直接返回
    if (_cachedControllers.containsKey(videoUrl)) {
      return _cachedControllers[videoUrl];
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: {
          'Accept-Encoding': 'identity',
        },
      );

      await controller.initialize();
      
      // 静音播放一小段时间来缓冲视频
      await controller.setVolume(0);
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 300));
      await controller.pause();
      await controller.seekTo(Duration.zero);

      // 添加到缓存
      _cachedControllers[videoUrl] = controller;
      
      // 如果缓存超过最大数量，移除最早的
      if (_cachedControllers.length > maxCacheSize) {
        final firstKey = _cachedControllers.keys.first;
        _cachedControllers[firstKey]?.dispose();
        _cachedControllers.remove(firstKey);
      }

      debugPrint('视频预加载成功: $videoUrl');
      return controller;
    } catch (e) {
      debugPrint('视频预加载失败: $e');
      return null;
    }
  }

  /// 获取缓存的视频控制器
  VideoPlayerController? getCachedController(String videoUrl) {
    return _cachedControllers[videoUrl];
  }

  /// 移除指定视频的缓存
  void removeCache(String videoUrl) {
    final controller = _cachedControllers.remove(videoUrl);
    controller?.dispose();
  }

  /// 清空所有缓存
  void clearAll() {
    for (var controller in _cachedControllers.values) {
      controller.dispose();
    }
    _cachedControllers.clear();
    debugPrint('已清空所有视频缓存');
  }

  /// 获取当前缓存数量
  int get cacheSize => _cachedControllers.length;
}

