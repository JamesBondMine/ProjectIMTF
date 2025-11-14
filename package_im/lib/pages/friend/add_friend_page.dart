import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

/// 添加好友页面
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _formKey = GlobalKey<FormState>();
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
      appBar: AppBar(
        title: const Text('添加好友'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 搜索提示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '输入对方的账号或邮箱来搜索好友',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 搜索框
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _accountController,
                      decoration: InputDecoration(
                        labelText: '账号/邮箱',
                        hintText: '请输入账号或邮箱',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) => _searchUser(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('搜索'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // 搜索结果
              if (_searchResult != null) ...[
                const Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchResult(),
                const SizedBox(height: 24),
                // 只有当不是好友时才显示备注输入框和添加按钮
                if (_searchResult!.isFriend != true) ...[
                  // 备注输入框
                  TextFormField(
                    controller: _remarkController,
                    decoration: InputDecoration(
                      labelText: '备注名（可选）',
                      hintText: '给好友设置备注名',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 添加按钮
                  ElevatedButton(
                    onPressed: _isAdding ? null : _addFriend,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 搜索结果卡片
  Widget _buildSearchResult() {
    if (_searchResult == null) return const SizedBox();

    final bool isFriend = _searchResult!.isFriend == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: _searchResult!.avatarUrl != null
                  ? NetworkImage(_searchResult!.avatarUrl!)
                  : null,
              child: _searchResult!.avatarUrl == null
                  ? Text(
                      _searchResult!.nickname.isNotEmpty
                          ? _searchResult!.nickname[0].toUpperCase()
                          : _searchResult!.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchResult!.username,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchResult!.phone != null &&
                      _searchResult!.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _searchResult!.phone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 状态标识
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isFriend ? Colors.blue[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFriend ? Icons.check_circle : Icons.person_add_outlined,
                    size: 14,
                    color: isFriend ? Colors.blue[700] : Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFriend ? '已是好友' : '可添加',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFriend ? Colors.blue[700] : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

