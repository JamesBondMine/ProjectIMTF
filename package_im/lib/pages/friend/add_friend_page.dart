import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/friend.dart';

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
  bool _isSearching = false;
  bool _isAdding = false;
  Friend? _searchResult;

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
      // TODO: 调用API搜索用户
      // final response = await ApiService().searchUser(_accountController.text.trim());
      
      // 模拟延迟
      await Future.delayed(const Duration(seconds: 1));

      // 模拟搜索结果
      final mockUser = Friend(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '1',
        friendId: '2',
        friendUsername: _accountController.text.trim(),
        friendNickname: '测试用户',
        friendAvatarUrl: null,
        friendPhone: '13800138000',
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      setState(() {
        _searchResult = mockUser;
      });
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
      // TODO: 调用API添加好友
      // final response = await ApiService().addFriend(
      //   friendId: _searchResult!.friendId,
      //   remark: _remarkController.text.trim(),
      // );

      // 模拟延迟
      await Future.delayed(const Duration(seconds: 1));

      // 创建好友对象并返回
      final friend = _searchResult!.copyWith(
        remark: _remarkController.text.trim(),
        status: 'ACCEPTED',
        createdAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.of(context).pop(friend);
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
          ),
        ),
      ),
    );
  }

  /// 搜索结果卡片
  Widget _buildSearchResult() {
    if (_searchResult == null) return const SizedBox();

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
              backgroundImage: _searchResult!.friendAvatarUrl != null
                  ? NetworkImage(_searchResult!.friendAvatarUrl!)
                  : null,
              child: _searchResult!.friendAvatarUrl == null
                  ? Text(
                      _searchResult!.friendNickname.isNotEmpty
                          ? _searchResult!.friendNickname[0].toUpperCase()
                          : '?',
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
                    _searchResult!.friendNickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchResult!.friendUsername,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_searchResult!.friendPhone != null &&
                      _searchResult!.friendPhone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _searchResult!.friendPhone!,
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
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '找到了',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

