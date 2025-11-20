import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// 视频分享助手
class VideoShareHelper {
  // 缓存的视频文件路径（URL -> 本地路径）
  static final Map<String, String> _cachedVideos = {};
  
  // 用于控制进度更新频率（避免闪烁）
  static int _lastProgressUpdate = 0;
  /// 显示分享选项弹窗
  static void showShareOptions(
    BuildContext context, {
    required String videoUrl,
    required String videoTitle,
    String? coverUrl,
    VoidCallback? onShareSuccess,
    VoidCallback? onSaveSuccess,  // 新增：保存成功的回调
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareOptionsSheet(
        videoUrl: videoUrl,
        videoTitle: videoTitle,
        coverUrl: coverUrl,
        onShareSuccess: onShareSuccess,
        onSaveSuccess: onSaveSuccess,
      ),
    );
  }

  /// 下载视频到缓存（带缓存复用机制）
  static Future<String?> _downloadVideoToCache(String videoUrl) async {
    try {
      // 1. 检查是否已缓存
      if (_cachedVideos.containsKey(videoUrl)) {
        final cachedPath = _cachedVideos[videoUrl]!;
        // 验证文件是否还存在
        if (await File(cachedPath).exists()) {
          debugPrint('使用缓存的视频: $cachedPath');
          return cachedPath;
        } else {
          // 文件已被删除，移除缓存记录
          _cachedVideos.remove(videoUrl);
        }
      }

      // 2. 生成缓存文件名（使用URL的hashCode）
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/video_cache');
      
      // 创建缓存目录
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      // 使用URL的hash作为文件名，避免重复
      final urlHash = videoUrl.hashCode.abs().toString();
      final fileName = 'video_$urlHash.mp4';
      final filePath = '${cacheDir.path}/$fileName';

      // 3. 下载视频
      debugPrint('开始下载视频: $videoUrl');
      debugPrint('保存路径: $filePath');
      
      final dio = Dio();
      await dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          debugPrint('下载进度: $received');
          if (total > 0) {
            // 节流：每200ms更新一次进度，避免闪烁
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastProgressUpdate > 200) {
              final progress = (received / total * 100).toStringAsFixed(0);
              EasyLoading.show(status: '下载中 $progress%');
              _lastProgressUpdate = now;
            }
          }
        },
      );

      // 4. 下载成功，加入缓存
      _cachedVideos[videoUrl] = filePath;
      debugPrint('视频下载完成，已缓存: $filePath');
      
      return filePath;
    } catch (e) {
      debugPrint('下载视频失败: $e');
      return null;
    }
  }

  /// 保存视频到相册
  static Future<bool> saveToGallery(String videoUrl) async {
    try {
      EasyLoading.show(status: '准备下载...');

      // 1. 请求存储权限
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        EasyLoading.dismiss();
        EasyLoading.showError('需要存储权限才能保存视频');
        return false;
      }

      // 2. 下载视频到缓存（会自动复用已下载的视频）
      EasyLoading.show(status: '下载中...');
      final filePath = await _downloadVideoToCache(videoUrl);
      
      if (filePath == null) {
        EasyLoading.dismiss();
        EasyLoading.showError('下载失败');
        return false;
      }

      // 3. 保存到相册
      EasyLoading.show(status: '保存中...');
      
      final result = await ImageGallerySaver.saveFile(
        filePath,
        isReturnPathOfIOS: true,
      );

      EasyLoading.dismiss();

      if (result != null && result['isSuccess'] == true) {
        EasyLoading.showSuccess('保存成功');
        return true;
      } else {
        EasyLoading.showError('保存失败');
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('保存视频失败: $e');
      EasyLoading.showError('保存失败: ${e.toString()}');
      return false;
    }
  }

  /// 系统分享（分享视频链接）
  static Future<void> shareToSystem(
    String videoUrl,
    String videoTitle,
  ) async {
    try {
      // 直接分享视频链接文本，不下载视频
      final shareText = '''$videoTitle

观看视频：$videoUrl

分享自短视频APP''';

      await Share.share(
        shareText,
        subject: videoTitle,
      );

      // 注意：share 方法不会返回 ShareResult，所以不需要判断状态
      // 如果需要，可以延迟显示提示
      Future.delayed(const Duration(milliseconds: 300), () {
        // 分享面板已打开，不显示额外提示
      });
    } catch (e) {
      debugPrint('分享失败: $e');
      EasyLoading.showError('分享失败');
    }
  }

  /// 复制链接
  static Future<void> copyLink(String videoUrl, String videoTitle) async {
    try {
      // 生成分享文本
      final shareText = '''$videoTitle

观看视频：$videoUrl''';
      
      // 使用系统分享，用户可以选择复制或分享到其他应用
      await Share.share(shareText);
      
    } catch (e) {
      debugPrint('复制链接失败: $e');
      EasyLoading.showError('操作失败');
    }
  }

  /// 请求存储权限
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 使用新的媒体权限
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        // Android 12 及以下使用存储权限
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS 保存到相册需要使用 photosAddOnly 权限
      // 先检查是否已有权限
      var status = await Permission.photosAddOnly.status;
      
      if (status.isGranted) {
        return true;
      }
      
      // 如果没有权限，请求权限
      status = await Permission.photosAddOnly.request();
      
      if (status.isGranted) {
        return true;
      }
      return true;
      // 如果被拒绝，提示用户去设置中开启
      // if (status.isDenied || status.isPermanentlyDenied) {
      //   EasyLoading.showError('请在设置中允许访问相册');
      //   // 可以引导用户去设置
      //   await Future.delayed(const Duration(seconds: 2));
      //   await openAppSettings();
      // }
      
      // return false;
    }
    return false;
  }

  /// 检查是否是 Android 13 或更高版本
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      // Android SDK 33 对应 Android 13
      // 可以通过 device_info_plus 获取准确版本，这里简化处理
      // 先尝试新权限，不可用则使用旧权限
      try {
        final photosStatus = await Permission.photos.status;
        // 如果 photos 权限可用，说明是 Android 13+
        return photosStatus != PermissionStatus.permanentlyDenied;
      } catch (e) {
        // 如果不支持 photos 权限，说明是旧版本
        return false;
      }
    }
    return false;
  }

  /// 清理所有视频缓存
  static Future<void> clearAllCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/video_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        _cachedVideos.clear();
        debugPrint('已清理所有视频缓存');
      }
    } catch (e) {
      debugPrint('清理缓存失败: $e');
    }
  }

  /// 获取缓存大小（字节）
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/video_cache');
      
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('获取缓存大小失败: $e');
      return 0;
    }
  }

  /// 格式化缓存大小
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 获取缓存的视频数量
  static int getCachedVideoCount() {
    return _cachedVideos.length;
  }
}

/// 分享选项底部弹窗
class _ShareOptionsSheet extends StatelessWidget {
  final String videoUrl;
  final String videoTitle;
  final String? coverUrl;
  final VoidCallback? onShareSuccess;
  final VoidCallback? onSaveSuccess;  // 新增：保存成功的回调

  const _ShareOptionsSheet({
    required this.videoUrl,
    required this.videoTitle,
    this.coverUrl,
    this.onShareSuccess,
    this.onSaveSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '分享到',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 分享选项
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 保存到相册
                  _ShareOption(
                    icon: Icons.download,
                    label: '保存到相册',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await VideoShareHelper.saveToGallery(videoUrl);
                      if (success) {
                        // 保存成功，调用保存回调（不调用分享回调）
                        onSaveSuccess?.call();
                      }
                    },
                  ),

                  // 分享好友
                  _ShareOption(
                    icon: Icons.share,
                    label: '分享好友',
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(context);
                      debugPrint('分享好友:$videoUrl');
                      debugPrint('分享好友:$videoTitle');
                      await VideoShareHelper.shareToSystem(videoUrl, videoTitle);
                      onShareSuccess?.call();
                    },
                  ),

                  // 更多分享
                  _ShareOption(
                    icon: Icons.more_horiz,
                    label: '更多分享',
                    color: Colors.orange,
                    onTap: () async {
                      Navigator.pop(context);
                      await VideoShareHelper.copyLink(videoUrl, videoTitle);
                      onShareSuccess?.call();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// 分享选项按钮
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

