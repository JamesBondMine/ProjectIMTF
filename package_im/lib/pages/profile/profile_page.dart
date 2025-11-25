import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../models/department.dart';
import '../login/login_page.dart';
import '../login/agreement_page.dart';
import 'feedback_page.dart';
import 'emoji_manager_page.dart';

/// 个人信息页面
class ProfilePage extends StatefulWidget {
  final VoidCallback? onClose;  // 可选的关闭回调
  
  const ProfilePage({super.key, this.onClose});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  List<DepartmentMember> _myDepartments = [];
  bool _isLoadingDepartments = false;

  @override
  void initState() {
    super.initState();
    _refreshUserInfo();
    _loadMyDepartments();
  }

  /// 刷新用户信息
  Future<void> _refreshUserInfo() async {
    try {
      await _apiService.getCurrentUserInfo();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
  }

  /// 加载当前用户的部门信息
  Future<void> _loadMyDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final response = await _apiService.getMyDepartments();

      if (response.success && response.data != null) {
        setState(() {
          _myDepartments = response.data!
              .map((json) => DepartmentMember.fromJson(json as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('加载用户部门信息失败: $e');
    } finally {
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;
    
    // 判断是否作为侧边面板使用
    final isDrawerMode = widget.onClose != null;

    return Scaffold(
      appBar: isDrawerMode ? null : AppBar(
        title: const Text('个人信息'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 如果是侧边面板模式，添加顶部栏
          if (isDrawerMode) _buildDrawerHeader(),
          // 可滚动内容
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
            // 顶部用户信息卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  // 头像（可点击上传）
                  GestureDetector(
                    onTap: _showAvatarOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  user?.nickname.isNotEmpty == true
                                      ? user!.nickname[0].toUpperCase()
                                      : user?.username[0].toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        // 相机图标
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 昵称
                  Text(
                    user?.nickname ?? user?.username ?? '未知用户',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 账号
                  Text(
                    user?.username ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 信息列表
            _buildInfoSection(),
            const SizedBox(height: 16),
            // 设置列表
            _buildSettingSection(),
            const SizedBox(height: 32),
            // 退出登录按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '退出登录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建侧边面板顶部栏
  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '个人信息',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  /// 信息区域
  Widget _buildInfoSection() {
    final user = _apiService.currentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEditableInfoItem(
            icon: Icons.person_outline,
            title: '昵称',
            value: user?.nickname ?? '未设置',
            onTap: _showEditNicknameDialog,
          ),
          const Divider(height: 1, indent: 56),
          _buildEditableInfoItem(
            icon: Icons.phone_outlined,
            title: '手机号',
            value: user?.phone ?? '未设置',
            onTap: _showEditPhoneDialog,
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoItem(
            imagePath: 'assets/images/youxiang.png',
            title: '邮箱',
            value: user?.email ?? '未设置',
          ),
          const Divider(height: 1, indent: 56),
          _buildDepartmentInfoItem(),
        ],
      ),
    );
  }

  /// 设置区域
  Widget _buildSettingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingItem(
            imagePath: 'assets/images/anquanyinsi.png',
            title: '隐私协议',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AgreementPage(
                    title: '隐私协议',
                    htmlFile: 'privacy_policy.html',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            imagePath: 'assets/images/yonghuxieyi.png',
            title: '用户协议',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AgreementPage(
                    title: '用户协议',
                    htmlFile: 'user_agreement.html',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            imagePath: 'assets/images/tousu.png',
            title: '投诉建议',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeedbackPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            icon: Icons.emoji_emotions_rounded,
            title: '表情管理',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmojiManagerPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingItem(
            imagePath: 'assets/images/guanyu.png',
            title: '关于',
            onTap: () {
              _showAboutDialog();
            },
          ),
          
        ],
      ),
    );
  }

  /// 部门信息项
  Widget _buildDepartmentInfoItem() {
    final user = _apiService.currentUser;
    
    // 优先使用用户信息中的主部门
    if (user?.primaryDepartmentName != null && user!.primaryDepartmentName!.isNotEmpty) {
      return InkWell(
        onTap: _myDepartments.isNotEmpty ? _showDepartmentDetail : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.grey[600]),
              const SizedBox(width: 32),
              const Text(
                '部门',
                style: TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.primaryDepartmentName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_myDepartments.length > 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${_myDepartments.length - 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user.entryDate != null && user.entryDate!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '入职: ${user.entryDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              if (_myDepartments.isNotEmpty)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      );
    }
    
    // 加载中状态
    if (_isLoadingDepartments) {
      return ListTile(
        leading: Icon(Icons.business, color: Colors.grey[600]),
        title: const Text(
          '部门',
          style: TextStyle(fontSize: 14),
        ),
        trailing: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 如果有部门详情数据，使用详情数据
    if (_myDepartments.isNotEmpty) {
      // 查找主部门
      final primaryDept = _myDepartments.firstWhere(
        (dept) => dept.isPrimary,
        orElse: () => _myDepartments.first,
      );

      return InkWell(
        onTap: _showDepartmentDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.grey[600]),
              const SizedBox(width: 32),
              const Text(
                '部门',
                style: TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        primaryDept.departmentName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_myDepartments.length > 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${_myDepartments.length - 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    primaryDept.position,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      );
    }

    // 未分配部门
    return ListTile(
      leading: Icon(Icons.business, color: Colors.grey[600]),
      title: const Text(
        '部门',
        style: TextStyle(fontSize: 14),
      ),
      trailing: Text(
        '未分配',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 信息项
  Widget _buildInfoItem({
    IconData? icon,
    String? imagePath,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      leading: imagePath != null
          ? Image.asset(
              imagePath,
              width: 24,
              height: 24,
              color: Colors.grey[600],
            )
          : Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: valueColor ?? Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 可编辑的信息项
  Widget _buildEditableInfoItem({
    IconData? icon,
    String? imagePath,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: imagePath != null
          ? Image.asset(
              imagePath,
              width: 24,
              height: 24,
              color: Colors.grey[600],
            )
          : Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }

  /// 设置项
  Widget _buildSettingItem({
    IconData? icon,
    String? imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: imagePath != null
          ? Image.asset(
              imagePath,
              width: 24,
              height: 24,
              color: Colors.grey[600],
            )
          : Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  /// 显示部门详情
  void _showDepartmentDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头部
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '我的部门',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // 部门列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _myDepartments.length,
                  itemBuilder: (context, index) {
                    final dept = _myDepartments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dept.isPrimary
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200]!,
                          width: dept.isPrimary ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.business,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dept.departmentName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (dept.isPrimary)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '主部门',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDeptDetailRow(
                              Icons.work_outline,
                              '职位',
                              dept.position,
                            ),
                            const SizedBox(height: 8),
                            _buildDeptDetailRow(
                              Icons.calendar_today,
                              '入职日期',
                              dept.joinDate,
                            ),
                            const SizedBox(height: 8),
                            _buildDeptDetailRow(
                              Icons.info_outline,
                              '状态',
                              dept.statusText,
                            ),
                            if (dept.isLeader) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '部门负责人',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建部门详情行
  Widget _buildDeptDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于蜻蜓翼'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 1.0.0'),
            SizedBox(height: 8),
            Text('开发者: Flutter Team'),
            SizedBox(height: 8),
            Text('Copyright © 2024'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示头像选项
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('取消'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      // 显示压缩提示
      EasyLoading.show(status: '处理中...');

      // 压缩图片（头像不需要很高清晰度）
      final compressedImage = await _compressImage(image.path);
      
      EasyLoading.dismiss();

      if (compressedImage == null) {
        EasyLoading.showError('图片处理失败');
        return;
      }

      // 上传压缩后的图片
      await _uploadAvatar(compressedImage.path);
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('选择图片失败: $e');
    }
  }

  /// 压缩图片（头像专用）
  Future<XFile?> _compressImage(String filePath) async {
    try {
      // 生成压缩后的文件路径
      final targetPath = filePath.replaceAll('.jpg', '_compressed.jpg')
          .replaceAll('.png', '_compressed.jpg')
          .replaceAll('.jpeg', '_compressed.jpg');

      // 压缩图片：头像只需要 512x512，质量 70 就够了
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        minWidth: 512,
        minHeight: 512,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        // 计算压缩比例
        final originalSize = await File(filePath).length();
        final compressedSize = await File(result.path).length();
        final ratio = ((1 - compressedSize / originalSize) * 100).toInt();
        
        debugPrint('✅ 头像压缩完成: ${(originalSize / 1024).toInt()}KB → ${(compressedSize / 1024).toInt()}KB (压缩了 $ratio%)');
      }

      return result;
    } catch (e) {
      debugPrint('❌ 图片压缩失败: $e');
      // 压缩失败时返回原图
      return XFile(filePath);
    }
  }

  /// 上传头像
  Future<void> _uploadAvatar(String filePath) async {
    try {
      EasyLoading.show(status: '上传中...');

      // 1. 上传文件获取URL
      final uploadResult = await _apiService.uploadSingleFile(filePath);

      if (!uploadResult.success || uploadResult.data == null) {
        EasyLoading.showError('上传失败');
        return;
      }

      String avatarUrl = uploadResult.data!;
      
      // 2. 使用URL更新用户信息
      final updateResult = await _apiService.updateUserInfo(
        avatarUrl: avatarUrl,
      );

      if (updateResult.success) {
        EasyLoading.showSuccess('头像更新成功');
        
        // 3. 从服务器刷新用户信息
        await _apiService.getCurrentUserInfo();
        
        // 4. 刷新UI
        if (mounted) {
          setState(() {});
        }
      } else {
        EasyLoading.showError('头像更新失败');
      }
    } catch (e) {
      EasyLoading.showError('上传失败: $e');
    }
  }

  /// 显示修改昵称对话框
  void _showEditNicknameDialog() {
    final user = _apiService.currentUser;
    final TextEditingController nicknameController = TextEditingController(
      text: user?.nickname ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('修改昵称'),
          content: TextField(
            controller: nicknameController,
            autofocus: true,
            maxLength: 20,
            decoration: const InputDecoration(
              hintText: '请输入新昵称',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newNickname = nicknameController.text.trim();
                if (newNickname.isEmpty) {
                  EasyLoading.showError('昵称不能为空');
                  return;
                }
                Navigator.of(context).pop();
                _updateNickname(newNickname);
              },
              child: Text(
                '确定',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 更新昵称
  Future<void> _updateNickname(String nickname) async {
    try {
      EasyLoading.show(status: '更新中...');

      final result = await _apiService.updateUserInfo(nickname: nickname);

      if (result.success) {
        EasyLoading.showSuccess('昵称更新成功');
        
        // 从服务器刷新用户信息
        await _apiService.getCurrentUserInfo();
        
        // 刷新UI
        if (mounted) {
          setState(() {});
        }
      } else {
        EasyLoading.showError(result.message.isEmpty ? '昵称更新失败' : result.message);
      }
    } catch (e) {
      EasyLoading.showError('更新失败: $e');
    }
  }

  /// 显示修改手机号对话框
  void _showEditPhoneDialog() {
    final user = _apiService.currentUser;
    final TextEditingController phoneController = TextEditingController(
      text: user?.phone ?? '',
    );
    String errorText = '';
    int charCount = phoneController.text.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text('设置手机号'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 当前手机号提示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user?.phone != null && user!.phone!.isNotEmpty
                                  ? '当前手机号：${_formatPhoneDisplay(user.phone!)}'
                                  : '当前未设置手机号',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 输入框
                    TextField(
                      controller: phoneController,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      decoration: InputDecoration(
                        labelText: '手机号',
                        hintText: '请输入11位手机号',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        counterText: '',
                        errorText: errorText.isEmpty ? null : errorText,
                        suffixIcon: phoneController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    phoneController.clear();
                                    charCount = 0;
                                    errorText = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        // 只允许输入数字
                        final filteredValue = value.replaceAll(RegExp(r'[^\d]'), '');
                        if (filteredValue != value) {
                          phoneController.value = TextEditingValue(
                            text: filteredValue,
                            selection: TextSelection.collapsed(
                              offset: filteredValue.length,
                            ),
                          );
                        }
                        
                        setState(() {
                          charCount = filteredValue.length;
                          errorText = _validatePhone(filteredValue);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // 字符计数和格式化预览
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 格式化预览
                        if (phoneController.text.isNotEmpty && errorText.isEmpty)
                          Text(
                            _formatPhoneDisplay(phoneController.text),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const SizedBox(),
                        // 字符计数
                        Text(
                          '$charCount/11',
                          style: TextStyle(
                            fontSize: 12,
                            color: charCount == 11
                                ? Theme.of(context).primaryColor
                                : charCount > 11
                                    ? Colors.red
                                    : Colors.grey[600],
                            fontWeight: charCount == 11 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 规则说明
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.rule_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '手机号规则',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildRuleItem('长度：11位数字'),
                          _buildRuleItem('格式：1开头的手机号'),
                          _buildRuleItem('支持：移动、联通、电信'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newPhone = phoneController.text.trim();
                    final error = _validatePhone(newPhone);
                    
                    if (error.isNotEmpty) {
                      setState(() {
                        errorText = error;
                      });
                      return;
                    }
                    
                    if (newPhone == user?.phone) {
                      EasyLoading.showInfo('手机号未修改');
                      return;
                    }
                    
                    Navigator.of(context).pop();
                    _updatePhone(newPhone);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 验证手机号
  String _validatePhone(String phone) {
    if (phone.isEmpty) {
      return '手机号不能为空';
    }
    
    if (phone.length != 11) {
      return '手机号必须是11位数字';
    }
    
    // 验证手机号格式：1开头，第二位是3-9
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      return '请输入正确的手机号格式';
    }
    
    return '';
  }

  /// 格式化手机号显示（带空格）
  String _formatPhoneDisplay(String phone) {
    if (phone.length <= 3) {
      return phone;
    } else if (phone.length <= 7) {
      return '${phone.substring(0, 3)} ${phone.substring(3)}';
    } else if (phone.length <= 11) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  /// 构建规则项
  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 更新手机号
  Future<void> _updatePhone(String phone) async {
    try {
      EasyLoading.show(status: '更新中...');

      final result = await _apiService.updateUserInfo(phone: phone);

      if (result.success) {
        EasyLoading.showSuccess('手机号更新成功');
        
        // 从服务器刷新用户信息
        await _apiService.getCurrentUserInfo();
        
        // 刷新UI
        if (mounted) {
          setState(() {});
        }
      } else {
        EasyLoading.showError(result.message.isEmpty ? '手机号更新失败' : result.message);
      }
    } catch (e) {
      EasyLoading.showError('更新失败: $e');
    }
  }

  /// 显示退出登录对话框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // 显示加载
                EasyLoading.show(status: '退出中...');
                
                // 调用退出登录API
                await _apiService.logout();
                
                EasyLoading.dismiss();
                
                // 返回登录页面
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                '退出',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

