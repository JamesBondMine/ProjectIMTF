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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          '发布动态',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _handlePublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                disabledBackgroundColor: Colors.white54,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '发布',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 输入内容区域
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _contentController,
                      maxLines: 8,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: '分享新鲜事...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w400,
                        ),
                        counterStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // 快捷标签
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickTag('☀️ 日常', () => _insertText('#☀️日常 ')),
                        _buildQuickTag('🍜 美食', () => _insertText('#🍜美食 ')),
                        _buildQuickTag('✈️ 旅行', () => _insertText('#✈️旅行 ')),
                        _buildQuickTag('📷 摄影', () => _insertText('#📷摄影 ')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 图片选择区域
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.photo_library_outlined,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '添加图片',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedImages.length}/9',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildImageGrid(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 提示信息
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.05),
                    Theme.of(context).primaryColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '发布提示',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('分享美好瞬间，传递正能量'),
                  _buildTipItem('尊重他人隐私，文明发言'),
                  _buildTipItem('内容需符合社区规范'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 快捷标签
  Widget _buildQuickTag(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 插入文本到光标位置
  void _insertText(String text) {
    final currentText = _contentController.text;
    final selection = _contentController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + text.length,
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.05),
                Theme.of(context).primaryColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '添加',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(XFile image, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(image.path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // 删除按钮
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.removeAt(index);
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 图片序号
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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

