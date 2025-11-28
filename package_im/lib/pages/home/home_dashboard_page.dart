import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:package_im/services/api_service.dart';
import 'package:package_im/models/pending_task.dart';
import 'package:package_im/pages/home/leave_detail_page.dart';
import 'package:package_im/pages/home/weekly_report_detail_page.dart';
import 'package:package_im/pages/home/monthly_report_detail_page.dart';

/// 首页
class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  // 待办列表
  final List<PendingTask> _todoList = [];
  
  // 已办列表
  final List<PendingTask> _doneList = [];
  
  bool _isLoading = false;
  
  // 分页参数
  int _todoPage = 0;
  int _donePage = 0;
  final int _pageSize = 10;
  bool _hasMoreTodo = true;
  bool _hasMoreDone = true;

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

  /// 加载数据（加载待办和已办）
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _todoPage = 0;
      _donePage = 0;
      _hasMoreTodo = true;
      _hasMoreDone = true;
    });

    try {
      // 并发加载待办和已办数据
      await Future.wait([
        _loadTodoData(isRefresh: true),
        _loadDoneData(isRefresh: true),
      ]);
    } catch (e) {
      EasyLoading.showError('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 加载待办数据
  Future<void> _loadTodoData({bool isRefresh = false}) async {
    if (!_hasMoreTodo && !isRefresh) return;
    
    try {
      final response = await _apiService.getTasks(
        isPending: true,
        page: isRefresh ? 0 : _todoPage,
        size: _pageSize,
      );
      
      if (response.success && response.data != null) {
        final pageData = PageData.fromJson(
          response.data!,
          (json) => PendingTask.fromJson(json),
        );
        
        setState(() {
          if (isRefresh) {
            _todoList.clear();
            _todoPage = 0;
          }
          _todoList.addAll(pageData.content);
          _hasMoreTodo = pageData.number < pageData.totalPages - 1;
          if (!isRefresh) {
            _todoPage++;
          }
        });
      } else {
        if (!isRefresh) {
          EasyLoading.showError(response.message);
        }
      }
    } catch (e) {
      debugPrint('加载待办列表失败: $e');
      if (!isRefresh) {
        EasyLoading.showError('加载待办列表失败: $e');
      }
    }
  }
  
  /// 加载已办数据
  Future<void> _loadDoneData({bool isRefresh = false}) async {
    if (!_hasMoreDone && !isRefresh) return;
    
    try {
      final response = await _apiService.getTasks(
        isPending: false,
        page: isRefresh ? 0 : _donePage,
        size: _pageSize,
      );
      
      if (response.success && response.data != null) {
        final pageData = PageData.fromJson(
          response.data!,
          (json) => PendingTask.fromJson(json),
        );
        
        setState(() {
          if (isRefresh) {
            _doneList.clear();
            _donePage = 0;
          }
          _doneList.addAll(pageData.content);
          _hasMoreDone = pageData.number < pageData.totalPages - 1;
          if (!isRefresh) {
            _donePage++;
          }
        });
      } else {
        if (!isRefresh) {
          EasyLoading.showError(response.message);
        }
      }
    } catch (e) {
      debugPrint('加载已办列表失败: $e');
      if (!isRefresh) {
        EasyLoading.showError('加载已办列表失败: $e');
      }
    }
  }

  /// 处理待办事项
  Future<void> _handleTodoItem(PendingTask item) async {
    // 根据类型跳转到对应的详情页面
    bool? needRefresh;
    
    switch (item.taskType) {
      case TaskType.LEAVE:
        // 跳转到请假详情页面
        if (mounted) {
          needRefresh = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => LeaveDetailPage(leaveId: item.taskId),
            ),
          );
        }
        break;
      case TaskType.WEEKLY_REPORT:
        // 跳转到周报详情页面
        if (mounted) {
          needRefresh = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => WeeklyReportDetailPage(
                reportId: item.taskId,
                taskData: item,
              ),
            ),
          );
        }
        break;
      case TaskType.MONTHLY_REPORT:
        // 跳转到月报详情页面
        if (mounted) {
          needRefresh = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => MonthlyReportDetailPage(
                reportId: item.taskId,
                taskData: item,
              ),
            ),
          );
        }
        break;
      case TaskType.APPROVAL:
        // TODO: 跳转到审批详情页面
        EasyLoading.showInfo('查看审批详情');
        break;
    }
    
    // 如果需要刷新，重新加载待办列表
    if (needRefresh == true && mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 美化的 TabBar 区域
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                padding: const EdgeInsets.all(4),
                tabs: [
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions, size: 18),
                        const SizedBox(width: 6),
                        const Text('待办'),
                        if (_todoList.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_todoList.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 6),
                        const Text('已办'),
                        if (_doneList.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_doneList.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodoList(),
                  _buildDoneList(),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _doneList.length,
        itemBuilder: (context, index) {
          return _buildDoneCard(_doneList[index]);
        },
      ),
    );
  }

  /// 构建待办卡片
  Widget _buildTodoCard(PendingTask item) {
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
              color: item.isUrgent ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
              width: item.isUrgent ? 2 : 1,
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
                    _buildTypeIcon(item.taskType),
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
                              if (item.isUrgent)
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.applicantName} - ${item.departmentName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 13,
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
                      _formatTime(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.statusDescription,
                        style: TextStyle(
                          fontSize: 11,
                          color: item.status.color,
                          fontWeight: FontWeight.bold,
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建已办卡片
  Widget _buildDoneCard(PendingTask item) {
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
                  _buildTypeIcon(item.taskType, done: true),
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
                            _buildStatusBadge(item.isApproved),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.applicantName} - ${item.departmentName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 13,
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
                    '提交于 ${_formatTime(item.createdAt)}',
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
  Widget _buildTypeIcon(TaskType type, {bool done = false}) {
    final icon = type.icon;
    final color = done ? Colors.grey : type.color;

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

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
