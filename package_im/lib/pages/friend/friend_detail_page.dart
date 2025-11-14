import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

/// 好友详情页面
class FriendDetailPage extends StatefulWidget {
  final User friend;

  const FriendDetailPage({
    super.key,
    required this.friend,
  });

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  final _apiService = ApiService();
  User? _detailedFriend;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  /// 加载用户详细信息
  Future<void> _loadUserDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUserById(widget.friend.id);

      if (response.success && response.data != null) {
        setState(() {
          _detailedFriend = response.data;
          _isLoading = false;
        });
        debugPrint('获取到用户详细信息: ${response.data!.toJson()}');
      } else {
        // 如果获取失败，使用传入的基本信息
        setState(() {
          _detailedFriend = widget.friend;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 出错时使用传入的基本信息
      setState(() {
        _detailedFriend = widget.friend;
        _isLoading = false;
      });
      debugPrint('获取用户详细信息失败: $e');
    }
  }

  // 获取当前显示的好友信息
  User get _currentFriend => _detailedFriend ?? widget.friend;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('好友详情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              } else if (value == 'remark') {
                EasyLoading.showInfo('设置备注功能待开发');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remark',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('设置备注'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除好友', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 头像和基本信息
                        _buildHeaderSection(),
                        const SizedBox(height: 16),
                        // 详细信息
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        // 如果有额外信息，显示更多信息卡片
                        if (_detailedFriend != null)
                          _buildAdditionalInfoSection(),
                      ],
                    ),
                  ),
                ),
                // 底部发消息按钮
                _buildBottomButton(),
              ],
            ),
    );
  }

  /// 头部信息区域
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            backgroundImage: _currentFriend.avatarUrl != null
                ? NetworkImage(_currentFriend.avatarUrl!)
                : null,
            child: _currentFriend.avatarUrl == null
                ? Text(
                    _currentFriend.nickname.isNotEmpty
                        ? _currentFriend.nickname[0].toUpperCase()
                        : _currentFriend.username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // 昵称
          Text(
            _currentFriend.nickname.isNotEmpty
                ? _currentFriend.nickname
                : _currentFriend.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 账号
          Text(
            _currentFriend.username,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          // 状态标签
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(_currentFriend.status),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 详细信息区域
  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.fingerprint,
            title: '用户ID',
            value: _currentFriend.id.toString(),
            showDivider: true,
          ),
          _buildInfoItem(
            icon: Icons.email_outlined,
            title: '邮箱',
            value: _currentFriend.email,
            showDivider: true,
          ),
          if (_currentFriend.phone != null && _currentFriend.phone!.isNotEmpty)
            _buildInfoItem(
              icon: Icons.phone_outlined,
              title: '手机号',
              value: _currentFriend.phone!,
              showDivider: true,
            ),
          _buildInfoItem(
            icon: Icons.badge_outlined,
            title: '用户类型',
            value: _getUserTypeText(_currentFriend.userType),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  /// 信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 48,
            color: Colors.grey[200],
          ),
      ],
    );
  }


  /// 底部发消息按钮
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '发消息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 发送消息
  void _sendMessage() {
    // TODO: 跳转到聊天页面
    EasyLoading.showInfo('聊天功能待开发');
  }

  /// 额外信息区域（从API获取到的更多信息）
  Widget _buildAdditionalInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                Icon(Icons.info_outline, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  '更多信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('注册时间', _formatDateTime(_currentFriend.createdAt)),
            const SizedBox(height: 8),
            _buildDetailRow('最后更新', _formatDateTime(_currentFriend.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化时间
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 显示删除对话框
  void _showDeleteDialog() {
    final displayName = _currentFriend.nickname.isNotEmpty
        ? _currentFriend.nickname
        : _currentFriend.username;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友"$displayName"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFriend();
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 删除好友
  void _deleteFriend() async {
    try {
      // TODO: 调用API删除好友
      EasyLoading.showSuccess('删除成功');

      // 返回上一页，并通知刷新列表
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      EasyLoading.showError('删除失败: $e');
    }
  }

  /// 获取用户类型文本
  String _getUserTypeText(String userType) {
    switch (userType) {
      case 'NORMAL':
        return '普通用户';
      case 'VIP':
        return 'VIP用户';
      case 'ADMIN':
        return '管理员';
      default:
        return '未知';
    }
  }

  /// 获取状态文本
  String _getStatusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return '在线';
      case 'INACTIVE':
        return '离线';
      case 'BANNED':
        return '已封禁';
      default:
        return '未知';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    switch (_currentFriend.status) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.grey;
      case 'BANNED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// 添加调试输出
void debugPrint(String message) {
  print(message);
}

