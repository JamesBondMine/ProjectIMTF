import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 组织架构页面
class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Department> _departments = [];
  List<Department> _filteredDepartments = [];
  bool _isLoading = false;
  int _selectedIndex = 0; // 0: 部门视图, 1: 员工列表

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载组织架构数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用API获取组织架构数据
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据
      setState(() {
        _departments = [
          Department(
            id: 1,
            name: '技术部',
            parentId: null,
            level: 1,
            manager: Employee(
              id: 1,
              name: '张三',
              position: '技术总监',
              avatar: '',
              phone: '13800138001',
              email: 'zhangsan@company.com',
            ),
            employeeCount: 25,
            children: [
              Department(
                id: 2,
                name: '前端组',
                parentId: 1,
                level: 2,
                manager: Employee(
                  id: 2,
                  name: '李四',
                  position: '前端组长',
                  avatar: '',
                  phone: '13800138002',
                  email: 'lisi@company.com',
                ),
                employeeCount: 8,
                children: [],
              ),
              Department(
                id: 3,
                name: '后端组',
                parentId: 1,
                level: 2,
                manager: Employee(
                  id: 3,
                  name: '王五',
                  position: '后端组长',
                  avatar: '',
                  phone: '13800138003',
                  email: 'wangwu@company.com',
                ),
                employeeCount: 10,
                children: [],
              ),
              Department(
                id: 4,
                name: '测试组',
                parentId: 1,
                level: 2,
                manager: Employee(
                  id: 4,
                  name: '赵六',
                  position: '测试组长',
                  avatar: '',
                  phone: '13800138004',
                  email: 'zhaoliu@company.com',
                ),
                employeeCount: 7,
                children: [],
              ),
            ],
          ),
          Department(
            id: 5,
            name: '产品部',
            parentId: null,
            level: 1,
            manager: Employee(
              id: 5,
              name: '孙七',
              position: '产品总监',
              avatar: '',
              phone: '13800138005',
              email: 'sunqi@company.com',
            ),
            employeeCount: 15,
            children: [
              Department(
                id: 6,
                name: 'C端产品组',
                parentId: 5,
                level: 2,
                manager: Employee(
                  id: 6,
                  name: '周八',
                  position: 'C端产品经理',
                  avatar: '',
                  phone: '13800138006',
                  email: 'zhouba@company.com',
                ),
                employeeCount: 8,
                children: [],
              ),
              Department(
                id: 7,
                name: 'B端产品组',
                parentId: 5,
                level: 2,
                manager: Employee(
                  id: 7,
                  name: '吴九',
                  position: 'B端产品经理',
                  avatar: '',
                  phone: '13800138007',
                  email: 'wujiu@company.com',
                ),
                employeeCount: 7,
                children: [],
              ),
            ],
          ),
          Department(
            id: 8,
            name: '市场部',
            parentId: null,
            level: 1,
            manager: Employee(
              id: 8,
              name: '郑十',
              position: '市场总监',
              avatar: '',
              phone: '13800138008',
              email: 'zhengshi@company.com',
            ),
            employeeCount: 12,
            children: [],
          ),
          Department(
            id: 9,
            name: '人力资源部',
            parentId: null,
            level: 1,
            manager: Employee(
              id: 9,
              name: '钱十一',
              position: 'HR总监',
              avatar: '',
              phone: '13800138009',
              email: 'qianshiyi@company.com',
            ),
            employeeCount: 6,
            children: [],
          ),
          Department(
            id: 10,
            name: '财务部',
            parentId: null,
            level: 1,
            manager: Employee(
              id: 10,
              name: '陈十二',
              position: '财务总监',
              avatar: '',
              phone: '13800138010',
              email: 'chenshier@company.com',
            ),
            employeeCount: 5,
            children: [],
          ),
        ];
        _filteredDepartments = _departments;
      });
    } catch (e) {
      EasyLoading.showError('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 搜索部门
  void _searchDepartment(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredDepartments = _departments;
      });
      return;
    }

    setState(() {
      _filteredDepartments = _departments.where((dept) {
        return dept.name.toLowerCase().contains(query.toLowerCase()) ||
            dept.manager.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  /// 查看部门详情
  void _viewDepartmentDetail(Department department) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepartmentDetailPage(department: department),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('组织架构'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索部门或人员',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchDepartment('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _searchDepartment,
                ),
              ),
              // Tab切换
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: '部门视图',
                        icon: Icons.account_tree,
                        isSelected: _selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: '员工列表',
                        icon: Icons.people,
                        isSelected: _selectedIndex == 1,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _selectedIndex == 0
                  ? _buildDepartmentView()
                  : _buildEmployeeView(),
            ),
    );
  }

  /// 构建Tab按钮
  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建部门视图
  Widget _buildDepartmentView() {
    if (_filteredDepartments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDepartments.length,
      itemBuilder: (context, index) {
        return _buildDepartmentCard(_filteredDepartments[index]);
      },
    );
  }

  /// 构建员工视图
  Widget _buildEmployeeView() {
    // 获取所有员工
    List<Employee> allEmployees = [];
    for (var dept in _departments) {
      allEmployees.add(dept.manager);
      for (var subDept in dept.children) {
        allEmployees.add(subDept.manager);
      }
    }

    if (allEmployees.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allEmployees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeCard(allEmployees[index]);
      },
    );
  }

  /// 构建部门卡片
  Widget _buildDepartmentCard(Department department) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewDepartmentDetail(department),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getDepartmentColor(department.level)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 28,
                        color: _getDepartmentColor(department.level),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                department.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${department.employeeCount}人',
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
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '负责人: ${department.manager.name}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                department.manager.position,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
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
              // 子部门
              if (department.children.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下属部门 (${department.children.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: department.children.map((subDept) {
                          return InkWell(
                            onTap: () => _viewDepartmentDetail(subDept),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    subDept.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建员工卡片
  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showEmployeeDetail(employee);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  employee.name.substring(0, 1),
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
                      employee.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.position,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, size: 20),
                    color: Colors.green,
                    onPressed: () {
                      // TODO: 拨打电话
                      EasyLoading.showInfo('拨打: ${employee.phone}');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, size: 20),
                    color: Colors.blue,
                    onPressed: () {
                      // TODO: 发送邮件
                      EasyLoading.showInfo('邮件: ${employee.email}');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示员工详情
  void _showEmployeeDetail(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  employee.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                employee.position,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(Icons.phone, '电话', employee.phone),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email, '邮箱', employee.email),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        EasyLoading.showInfo('拨打: ${employee.phone}');
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('拨打电话'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        EasyLoading.showInfo('发送邮件给: ${employee.email}');
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('发送邮件'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
}

/// 部门详情页面
class DepartmentDetailPage extends StatefulWidget {
  final Department department;

  const DepartmentDetailPage({super.key, required this.department});

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  List<Employee> _employees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  /// 加载部门员工
  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用API获取部门员工
      await Future.delayed(const Duration(milliseconds: 500));

      // 模拟数据
      setState(() {
        _employees = List.generate(
          widget.department.employeeCount,
          (index) => Employee(
            id: index + 100,
            name: '员工${index + 1}',
            position: index == 0 ? widget.department.manager.position : '普通员工',
            avatar: '',
            phone: '138001380${index.toString().padLeft(2, '0')}',
            email: 'employee${index + 1}@company.com',
          ),
        );
        // 替换第一个为部门经理
        _employees[0] = widget.department.manager;
      });
    } catch (e) {
      EasyLoading.showError('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.department.name),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 部门信息卡片
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.business,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.department.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '部门人数: ${widget.department.employeeCount}人',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.department.manager.name.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 18,
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
                                    const Text(
                                      '部门负责人',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.department.manager.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      widget.department.manager.position,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 子部门（如果有）
                  if (widget.department.children.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '下属部门',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.department.children.map((subDept) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.subdirectory_arrow_right,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            subDept.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text('${subDept.employeeCount}人'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DepartmentDetailPage(department: subDept),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // 部门成员列表
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '部门成员',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      final isManager = index == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Text(
                                  employee.name.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              if (isManager)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isManager) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '负责人',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(employee.position),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, size: 20),
                                color: Colors.green,
                                onPressed: () {
                                  EasyLoading.showInfo('拨打: ${employee.phone}');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.email, size: 20),
                                color: Colors.blue,
                                onPressed: () {
                                  EasyLoading.showInfo('邮件: ${employee.email}');
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

/// 部门模型
class Department {
  final int id;
  final String name;
  final int? parentId;
  final int level;
  final Employee manager;
  final int employeeCount;
  final List<Department> children;

  Department({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    required this.manager,
    required this.employeeCount,
    this.children = const [],
  });
}

/// 员工模型
class Employee {
  final int id;
  final String name;
  final String position;
  final String avatar;
  final String phone;
  final String email;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.avatar,
    required this.phone,
    required this.email,
  });
}

