import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../services/api_service.dart';

/// 发布短视频页面
class PublishVideoPage extends StatefulWidget {
  const PublishVideoPage({super.key});

  @override
  State<PublishVideoPage> createState() => _PublishVideoPageState();
}

class _PublishVideoPageState extends State<PublishVideoPage> {
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// 选择视频
  Future<void> _pickVideo({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // 限制5分钟
      );

      if (pickedFile != null) {
        setState(() {
          _videoFile = File(pickedFile.path);
          _isVideoInitialized = false;
        });

        // 初始化视频预览
        await _initializeVideo();
      }
    } catch (e) {
      debugPrint('选择视频失败: $e');
      EasyLoading.showError('选择视频失败');
    }
  }

  /// 初始化视频预览
  Future<void> _initializeVideo() async {
    if (_videoFile == null) return;

    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_videoFile!);
      await _videoController!.initialize();

      setState(() {
        _isVideoInitialized = true;
      });

      // 自动播放预览
      _videoController!.play();
      _videoController!.setLooping(true);
    } catch (e) {
      debugPrint('初始化视频失败: $e');
      EasyLoading.showError('视频加载失败');
    }
  }

  /// 发布视频
  Future<void> _publishVideo() async {
    if (_videoFile == null) {
      EasyLoading.showToast('请先选择视频');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      EasyLoading.showToast('请输入视频标题');
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      EasyLoading.showToast('请输入视频描述');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 第一步：上传视频文件
      EasyLoading.show(status: '正在上传视频...');

      final response = await _apiService.publishVideo(
        videoFile: _videoFile!,
        title: title,
        description: description,
      );

      if (response.success) {
        EasyLoading.showSuccess('发布成功！');
        // 返回 true 表示发布成功
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // 显示后端返回的错误信息
        final errorMsg = response.message.isNotEmpty ? response.message : '发布失败';
        debugPrint('发布失败: code=${response.code}, message=$errorMsg');
        EasyLoading.showError(errorMsg);
      }
    } catch (e) {
      debugPrint('发布视频异常: $e');
      // 显示友好的错误提示
      String errorMsg = '发布失败';
      if (e.toString().contains('网络')) {
        errorMsg = '网络连接失败，请检查网络';
      } else if (e.toString().contains('timeout')) {
        errorMsg = '请求超时，请稍后重试';
      } else {
        errorMsg = '发布失败: ${e.toString()}';
      }
      EasyLoading.showError(errorMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('发布视频'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_videoFile != null)
            TextButton(
              onPressed: _isUploading ? null : _publishVideo,
              child: Text(
                '发布',
                style: TextStyle(
                  color: _isUploading ? Colors.white54 : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 视频预览区域
            _buildVideoPreview(),
            const SizedBox(height: 24),

            // 选择视频按钮
            if (_videoFile == null) ...[
              _buildPickVideoButtons(),
              const SizedBox(height: 24),
            ],

            // 视频信息输入
            if (_videoFile != null) ...[
              // 标题
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '视频标题',
                  hintText: '给你的视频起个标题吧',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),

              // 描述
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '视频描述',
                  hintText: '介绍一下你的视频内容吧',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 200,
              ),
              const SizedBox(height: 24),

              // 重新选择按钮
              OutlinedButton.icon(
                onPressed: _isUploading ? null : () => _showPickOptions(),
                icon: const Icon(Icons.refresh),
                label: const Text('重新选择视频'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 视频预览
  Widget _buildVideoPreview() {
    if (_videoFile == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '请选择视频',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 视频播放器
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),

            // 播放/暂停按钮
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择视频按钮组
  Widget _buildPickVideoButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickVideo(fromCamera: false),
            icon: const Icon(Icons.photo_library),
            label: const Text('从相册选择'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickVideo(fromCamera: true),
            icon: const Icon(Icons.videocam),
            label: const Text('拍摄视频'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示选择选项
  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('拍摄视频'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(fromCamera: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

