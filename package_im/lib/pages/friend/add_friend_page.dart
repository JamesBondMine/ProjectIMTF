import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

/// 添加好友页面
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _accountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _apiService = ApiService();
  bool _isSearching = false;
  bool _isAdding = false;
  User? _searchResult;

  @override
  void dispose() {
    _accountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  /// 搜索用户
  Future<void> _searchUser() async {
    if (_accountController.text.trim().isEmpty) {
      EasyLoading.showError('请输入账号或邮箱');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
    });

    try {
      // 调用API搜索用户
      final response = await _apiService.searchUser(_accountController.text.trim());

      if (response.success && response.data != null) {
        setState(() {
          _searchResult = response.data;
        });
        
        // 如果已经是好友，提示用户
        if (_searchResult!.isFriend == true) {
          EasyLoading.showInfo('该用户已是您的好友');
        }
      } else {
        EasyLoading.showError(response.message.isEmpty ? '未找到该用户' : response.message);
      }
    } catch (e) {
      EasyLoading.showError('搜索失败: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 添加好友
  Future<void> _addFriend() async {
    if (_searchResult == null) return;

    setState(() {
      _isAdding = true;
    });

    try {
      // 调用API添加好友
      final response = await _apiService.addFriend(
        friendId: _searchResult!.id,
        remark: _remarkController.text.trim().isEmpty 
            ? null 
            : _remarkController.text.trim(),
      );

      if (response.success) {
        EasyLoading.showSuccess('添加好友成功');

        if (mounted) {
          // 返回上一页，触发好友列表刷新
          Navigator.of(context).pop(true);
        }
      } else {
        EasyLoading.showError(response.message.isEmpty ? '添加好友失败' : response.message);
      }
    } catch (e) {
      EasyLoading.showError('添加失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('添加好友'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 搜索区域
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          hintText: '搜索账号或邮箱',
                          prefixIcon: Icon(Icons.search, size: 22),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _searchUser(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isSearching ? null : _searchUser,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '搜索',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 搜索结果
            if (_searchResult != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSearchResult(),
                    // 只有当不是好友时才显示备注输入和添加按钮
                    if (_searchResult!.isFriend != true) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // 备注输入框
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _remarkController,
                                decoration: const InputDecoration(
                                  hintText: '备注名（可选）',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 添加按钮
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isAdding ? null : _addFriend,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: _isAdding
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        '添加好友',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 搜索结果卡片
  Widget _buildSearchResult() {
    if (_searchResult == null) return const SizedBox();

    final bool isFriend = _searchResult!.isFriend == true;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 头像
          _searchResult!.avatarUrl != null
              ? CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _searchResult!.avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            _searchResult!.nickname.isNotEmpty
                                ? _searchResult!.nickname[0].toUpperCase()
                                : _searchResult!.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    _searchResult!.nickname.isNotEmpty
                        ? _searchResult!.nickname[0].toUpperCase()
                        : _searchResult!.username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchResult!.nickname.isEmpty 
                      ? _searchResult!.username 
                      : _searchResult!.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _searchResult!.username,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 状态标识
          if (isFriend)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '已添加',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

