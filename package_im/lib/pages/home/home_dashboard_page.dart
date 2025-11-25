import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 首页
class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 待办列表
  final List<TodoItem> _todoList = [];
  
  // 已办列表
  final List<TodoItem> _doneList = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用API获取待办和已办数据
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟数据
      setState(() {
        _todoList.clear();
        _todoList.addAll([
          TodoItem(
            id: 1,
            title: '请假申请',
            description: '张三的事假申请，2024-11-26 至 2024-11-28',
            type: TodoType.leave,
            createTime: DateTime.now().subtract(const Duration(hours: 2)),
            urgent: true,
          ),
          TodoItem(
            id: 2,
            title: '周报审批',
            description: '李四提交的第47周周报',
            type: TodoType.weekly,
            createTime: DateTime.now().subtract(const Duration(hours: 5)),
            urgent: false,
          ),
          TodoItem(
            id: 3,
            title: '月报审批',
            description: '王五提交的11月工作月报',
            type: TodoType.monthly,
            createTime: DateTime.now().subtract(const Duration(days: 1)),
            urgent: false,
          ),
        ]);
        
        _doneList.clear();
        _doneList.addAll([
          TodoItem(
            id: 4,
            title: '请假申请',
            description: '赵六的病假申请，2024-11-20 至 2024-11-21',
            type: TodoType.leave,
            createTime: DateTime.now().subtract(const Duration(days: 2)),
            doneTime: DateTime.now().subtract(const Duration(days: 1)),
            urgent: false,
            approved: true,
          ),
          TodoItem(
            id: 5,
            title: '周报审批',
            description: '孙七提交的第46周周报',
            type: TodoType.weekly,
            createTime: DateTime.now().subtract(const Duration(days: 3)),
            doneTime: DateTime.now().subtract(const Duration(days: 2)),
            urgent: false,
            approved: true,
          ),
        ]);
      });
    } catch (e) {
      EasyLoading.showError('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 处理待办事项
  Future<void> _handleTodoItem(TodoItem item) async {
    // TODO: 根据类型跳转到对应的详情页面
    EasyLoading.showInfo('查看${item.title}详情');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('待办'),
                  if (_todoList.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_todoList.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: '已办'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodoList(),
          _buildDoneList(),
        ],
      ),
    );
  }

  /// 构建待办列表
  Widget _buildTodoList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todoList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        message: '暂无待办事项',
        submessage: '真棒！所有工作都完成了',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _todoList.length,
        itemBuilder: (context, index) {
          return _buildTodoCard(_todoList[index]);
        },
      ),
    );
  }

  /// 构建已办列表
  Widget _buildDoneList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_doneList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        message: '暂无已办事项',
        submessage: '最近没有处理过的事项',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _doneList.length,
        itemBuilder: (context, index) {
          return _buildDoneCard(_doneList[index]);
        },
      ),
    );
  }

  /// 构建待办卡片
  Widget _buildTodoCard(TodoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleTodoItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.urgent ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
              width: item.urgent ? 2 : 1,
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
                    _buildTypeIcon(item.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (item.urgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '紧急',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item.createTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建已办卡片
  Widget _buildDoneCard(TodoItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(item.type, done: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            _buildStatusBadge(item.approved ?? false),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已于 ${_formatTime(item.doneTime!)} 处理',
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
      ),
    );
  }

  /// 构建类型图标
  Widget _buildTypeIcon(TodoType type, {bool done = false}) {
    IconData icon;
    Color color;

    switch (type) {
      case TodoType.leave:
        icon = Icons.event_busy;
        color = Colors.orange;
        break;
      case TodoType.weekly:
        icon = Icons.calendar_view_week;
        color = Colors.blue;
        break;
      case TodoType.monthly:
        icon = Icons.calendar_month;
        color = Colors.green;
        break;
      case TodoType.approval:
        icon = Icons.approval;
        color = Colors.purple;
        break;
    }

    if (done) {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }

  /// 构建状态标签
  Widget _buildStatusBadge(bool approved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: approved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        approved ? '已通过' : '已驳回',
        style: TextStyle(
          fontSize: 11,
          color: approved ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String submessage,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    }
  }
}

/// 待办事项类型
enum TodoType {
  leave,    // 请假
  weekly,   // 周报
  monthly,  // 月报
  approval, // 审批
}

/// 待办事项模型
class TodoItem {
  final int id;
  final String title;
  final String description;
  final TodoType type;
  final DateTime createTime;
  final DateTime? doneTime;
  final bool urgent;
  final bool? approved;

  TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createTime,
    this.doneTime,
    this.urgent = false,
    this.approved,
  });
}
