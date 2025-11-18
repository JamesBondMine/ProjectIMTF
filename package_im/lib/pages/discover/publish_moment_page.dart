import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/api_service.dart';

/// 发布动态页面
class PublishMomentPage extends StatefulWidget {
  const PublishMomentPage({super.key});

  @override
  State<PublishMomentPage> createState() => _PublishMomentPageState();
}

class _PublishMomentPageState extends State<PublishMomentPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<XFile> _selectedImages = [];
  bool _isPublishing = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('发布动态'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _handlePublish,
            child: Text(
              '发布',
              style: TextStyle(
                color: _isPublishing ? Colors.white54 : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入内容区域
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: '分享你的生活...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 图片选择区域
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '添加图片（最多9张）',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImageGrid(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 提示信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '发布须知',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem('请遵守社区规范，发布健康积极的内容'),
                  _buildTipItem('不得发布违法违规、低俗色情等不良信息'),
                  _buildTipItem('尊重他人隐私，未经同意请勿发布他人照片'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length < 9 
          ? _selectedImages.length + 1 
          : _selectedImages.length,
      itemBuilder: (context, index) {
        if (index == _selectedImages.length && _selectedImages.length < 9) {
          // 添加图片按钮
          return _buildAddImageButton();
        }
        // 显示已选图片
        return _buildImageItem(_selectedImages[index], index);
      },
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              '添加图片',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(XFile image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(image.path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedImages.removeAt(index);
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 选择图片
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          // 计算还可以添加多少张
          final remainingSlots = 9 - _selectedImages.length;
          if (images.length <= remainingSlots) {
            _selectedImages.addAll(images);
          } else {
            _selectedImages.addAll(images.take(remainingSlots));
            EasyLoading.showToast('最多只能选择9张图片');
          }
        });
      }
    } catch (e) {
      EasyLoading.showError('选择图片失败');
    }
  }

  /// 发布动态
  Future<void> _handlePublish() async {
    // 验证内容
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      EasyLoading.showToast('请输入内容或选择图片');
      return;
    }

    if (content.isEmpty) {
      EasyLoading.showToast('请输入动态内容');
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      List<String> mediaUrls = [];

      // 如果有图片，先上传图片
      if (_selectedImages.isNotEmpty) {
        EasyLoading.show(status: '上传图片中...');
        
        for (int i = 0; i < _selectedImages.length; i++) {
          final image = _selectedImages[i];
          
          // 更新进度
          EasyLoading.show(
            status: '上传图片中... (${i + 1}/${_selectedImages.length})',
          );
          
          final response = await _apiService.uploadSingleFile(image.path);
          
          if (response.success && response.data != null && response.data!.isNotEmpty) {
            mediaUrls.add(response.data!);
          } else {
            throw Exception('图片上传失败');
          }
        }
        
        EasyLoading.dismiss();
      }

      // 发布动态
      EasyLoading.show(status: '发布中...');
      
      final response = await _apiService.publishMoment(
        content: content,
        mediaType: mediaUrls.isNotEmpty ? 'IMAGE' : 'TEXT',
        mediaUrls: mediaUrls,
      );

      EasyLoading.dismiss();

      if (mounted) {
        if (response.success) {
          EasyLoading.showSuccess('发布成功！');
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            // 返回并刷新列表
            Navigator.of(context).pop(true);
          }
        } else {
          EasyLoading.showError(response.message.isNotEmpty 
              ? response.message 
              : '发布失败');
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        EasyLoading.showError('发布失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }
}

