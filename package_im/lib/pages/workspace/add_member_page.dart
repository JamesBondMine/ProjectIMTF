import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:package_im/models/department.dart';
import 'package:package_im/models/user.dart';
import 'package:package_im/services/api_service.dart';

/// 添加成员到部门页面
class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  
  User? _selectedUser;
  Department? _selectedDepartment;
  List<Department> _allDepartments = [];
  DateTime _joinDate = DateTime.now();
  bool _isPrimary = true;
  bool _isLeader = false;
  bool _isSearching = false;
  bool _isLoadingDepartments = false;

  @override
  void initState() {
    super.initState();
    _loadAllDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  /// 加载所有部门列表
  Future<void> _loadAllDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final response = await _apiService.getAllDepartments();

      if (response.success && response.data != null) {
        setState(() {
          _allDepartments = response.data!
              .map((json) => Department.fromJson(json as Map<String, dynamic>))
              .toList();
          
          // 按level和sortOrder排序
          _allDepartments.sort((a, b) {
            if (a.level != b.level) {
              return a.level.compareTo(b.level);
            }
            return a.sortOrder.compareTo(b.sortOrder);
          });
        });
      } else {
        EasyLoading.showError(response.message.isNotEmpty 
            ? response.message 
            : '加载部门列表失败');
      }
    } catch (e) {
      EasyLoading.showError('加载部门列表失败: $e');
    } finally {
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  /// 搜索用户
  Future<void> _searchUser() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) {
      EasyLoading.showError('请输入用户名');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _apiService.searchUser(username);

      if (response.success && response.data != null) {
        setState(() {
          _selectedUser = response.data;
        });
        
        // 检查是否已经是好友
        if (_selectedUser!.isFriend == true) {
          EasyLoading.showInfo('该用户已在您的好友列表中');
        } else {
          final displayName = _selectedUser!.nickname.isNotEmpty 
              ? _selectedUser!.nickname 
              : _selectedUser!.username;
          EasyLoading.showSuccess('找到用户: $displayName');
        }
      } else {
        setState(() {
          _selectedUser = null;
        });
        EasyLoading.showError(response.message.isNotEmpty 
            ? response.message 
            : '未找到该用户');
      }
    } catch (e) {
      setState(() {
        _selectedUser = null;
      });
      EasyLoading.showError('搜索失败: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 选择部门
  void _selectDepartment() {
    if (_isLoadingDepartments) {
      EasyLoading.showInfo('正在加载部门列表...');
      return;
    }

    if (_allDepartments.isEmpty) {
      EasyLoading.showError('暂无可选部门');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '选择部门',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
              Expanded(
                child: _buildDepartmentList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建部门列表
  Widget _buildDepartmentList() {
    return ListView.builder(
      itemCount: _allDepartments.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final dept = _allDepartments[index];
        
        // 计算缩进级别
        final indentLevel = dept.level - 1;
        final leftPadding = 16.0 + (indentLevel * 24.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDepartment = dept;
                });
                Navigator.pop(context);
                EasyLoading.showSuccess('已选择: ${dept.name}');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.only(
                  left: leftPadding,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    // 层级指示器
                    if (dept.level > 1) ...[
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 部门图标
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getDepartmentColor(dept.level).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: _getDepartmentColor(dept.level),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 部门信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dept.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (dept.memberCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dept.memberCount}人',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (dept.hasLeader) ...[
                                Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    dept.leaderDisplayText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else
                                Expanded(
                                  child: Text(
                                    '暂无负责人',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 选择日期
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null && picked != _joinDate) {
      setState(() {
        _joinDate = picked;
      });
    }
  }

  /// 提交添加
  Future<void> _submit() async {
    // 验证
    if (_selectedUser == null) {
      EasyLoading.showError('请先搜索并选择用户');
      return;
    }

    if (_selectedDepartment == null) {
      EasyLoading.showError('请选择部门');
      return;
    }

    final position = _positionController.text.trim();
    if (position.isEmpty) {
      EasyLoading.showError('请输入职位');
      return;
    }

    try {
      final response = await _apiService.addUserToDepartment(
        userId: _selectedUser!.id,
        departmentId: _selectedDepartment!.id,
        position: position,
        isPrimary: _isPrimary,
        isLeader: _isLeader,
        joinDate: DateFormat('yyyy-MM-dd').format(_joinDate),
      );

      if (response.success) {
        EasyLoading.showSuccess('添加成功！');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        EasyLoading.showError(response.message.isNotEmpty 
            ? response.message 
            : '添加失败');
      }
    } catch (e) {
      EasyLoading.showError('添加失败: $e');
    }
  }

  /// 获取部门颜色
  Color _getDepartmentColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('添加成员'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索用户
              Text(
                '1. 搜索用户',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '输入用户名或手机号',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _searchUser(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _searchUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          : const Text('搜索'),
                    ),
                  ),
                ],
              ),
              
              // 显示搜索结果
              if (_selectedUser != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          (_selectedUser!.nickname.isNotEmpty 
                              ? _selectedUser!.nickname 
                              : _selectedUser!.username).substring(0, 1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedUser!.nickname.isNotEmpty 
                                  ? _selectedUser!.nickname 
                                  : _selectedUser!.username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedUser!.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 选择部门
              Text(
                '2. 选择部门',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDepartment,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: _selectedDepartment != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDepartment?.name ?? '点击选择部门',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedDepartment != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 职位信息
              Text(
                '3. 职位信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _positionController,
                decoration: InputDecoration(
                  hintText: '请输入职位（如：高级工程师）',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 其他设置
              Text(
                '4. 其他设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              // 加入日期
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '加入日期',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(_joinDate),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 是否为主部门
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: const Text('设为主部门'),
                  subtitle: const Text(
                    '员工可以隶属于多个部门，主部门为主要工作部门',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isPrimary,
                  onChanged: (value) {
                    setState(() {
                      _isPrimary = value ?? true;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 是否为部门负责人
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: const Text('设为部门负责人'),
                  subtitle: const Text(
                    '负责人拥有部门管理权限',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isLeader,
                  onChanged: (value) {
                    setState(() {
                      _isLeader = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '添加到部门',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

