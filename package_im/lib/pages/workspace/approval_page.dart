import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';

/// 审批页面
class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 待审批列表
  final List<ApprovalItem> _pendingList = [];

  // 已审批列表
  final List<ApprovalItem> _approvedList = [];

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
      // TODO: 调用API获取审批数据
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据
      setState(() {
        _pendingList.clear();
        _pendingList.addAll([
          ApprovalItem(
            id: 1,
            type: ApprovalType.leave,
            title: '张三的请假申请',
            applicant: '张三',
            department: '技术部',
            content: '因家中有事，申请事假3天',
            applyTime: DateTime.now().subtract(const Duration(hours: 2)),
            status: ApprovalStatus.pending,
            details: {
              'leaveType': '事假',
              'startDate': '2024-11-26',
              'endDate': '2024-11-28',
              'days': '3天',
              'reason': '因家中有事需要处理，特此申请事假3天，望批准。',
            },
          ),
          ApprovalItem(
            id: 2,
            type: ApprovalType.weekly,
            title: '李四的周报审批',
            applicant: '李四',
            department: '产品部',
            content: '2024年第47周工作周报',
            applyTime: DateTime.now().subtract(const Duration(hours: 5)),
            status: ApprovalStatus.pending,
            details: {
              'weekNumber': '47',
              'dateRange': '2024-11-18 至 2024-11-24',
              'thisWeek': '完成了用户需求分析，撰写了产品需求文档...',
              'nextWeek': '开始新功能的原型设计...',
            },
          ),
          ApprovalItem(
            id: 3,
            type: ApprovalType.monthly,
            title: '王五的月报审批',
            applicant: '王五',
            department: '研发部',
            content: '2024年10月工作月报',
            applyTime: DateTime.now().subtract(const Duration(days: 1)),
            status: ApprovalStatus.pending,
            details: {
              'month': '2024年10月',
              'summary': '本月主要完成了XXX项目的核心功能开发...',
              'achievements': '1. 完成XXX模块\n2. 优化XXX性能\n3. 修复XXX问题',
            },
          ),
        ]);

        _approvedList.clear();
        _approvedList.addAll([
          ApprovalItem(
            id: 4,
            type: ApprovalType.leave,
            title: '赵六的请假申请',
            applicant: '赵六',
            department: '市场部',
            content: '因病请假2天',
            applyTime: DateTime.now().subtract(const Duration(days: 3)),
            status: ApprovalStatus.approved,
            approveTime: DateTime.now().subtract(const Duration(days: 2)),
            approveComment: '同意请假，注意休息',
            details: {
              'leaveType': '病假',
              'startDate': '2024-11-20',
              'endDate': '2024-11-21',
              'days': '2天',
              'reason': '身体不适，需要就医治疗。',
            },
          ),
          ApprovalItem(
            id: 5,
            type: ApprovalType.weekly,
            title: '孙七的周报审批',
            applicant: '孙七',
            department: '设计部',
            content: '2024年第46周工作周报',
            applyTime: DateTime.now().subtract(const Duration(days: 5)),
            status: ApprovalStatus.rejected,
            approveTime: DateTime.now().subtract(const Duration(days: 4)),
            approveComment: '周报内容过于简单，请补充详细内容',
            details: {
              'weekNumber': '46',
              'dateRange': '2024-11-11 至 2024-11-17',
            },
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

  /// 处理审批
  void _handleApproval(ApprovalItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApprovalDetailPage(item: item),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('审批'),
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
                  const Text('待审批'),
                  if (_pendingList.isNotEmpty) ...[
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
                        '${_pendingList.length}',
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
            const Tab(text: '已审批'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildApprovedList(),
        ],
      ),
    );
  }

  /// 构建待审批列表
  Widget _buildPendingList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        message: '暂无待审批事项',
        submessage: '真棒！所有审批都处理完了',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingList.length,
        itemBuilder: (context, index) {
          return _buildApprovalCard(_pendingList[index], isPending: true);
        },
      ),
    );
  }

  /// 构建已审批列表
  Widget _buildApprovedList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_approvedList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        message: '暂无已审批事项',
        submessage: '最近没有处理过的审批',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _approvedList.length,
        itemBuilder: (context, index) {
          return _buildApprovalCard(_approvedList[index], isPending: false);
        },
      ),
    );
  }

  /// 构建审批卡片
  Widget _buildApprovalCard(ApprovalItem item, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleApproval(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPending
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.grey[200]!,
              width: isPending ? 2 : 1,
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isPending
                                        ? Colors.black87
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                              if (!isPending) _buildStatusBadge(item.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.applicant} · ${item.department}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      isPending
                          ? '申请于 ${_formatTime(item.applyTime)}'
                          : '审批于 ${_formatTime(item.approveTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              size: 12,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '待处理',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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

  /// 构建类型图标
  Widget _buildTypeIcon(ApprovalType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ApprovalType.leave:
        icon = Icons.event_busy;
        color = Colors.orange;
        break;
      case ApprovalType.weekly:
        icon = Icons.calendar_view_week;
        color = Colors.blue;
        break;
      case ApprovalType.monthly:
        icon = Icons.calendar_month;
        color = Colors.green;
        break;
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
  Widget _buildStatusBadge(ApprovalStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApprovalStatus.pending:
        color = Colors.orange;
        text = '待审批';
        break;
      case ApprovalStatus.approved:
        color = Colors.green;
        text = '已通过';
        break;
      case ApprovalStatus.rejected:
        color = Colors.red;
        text = '已驳回';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
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
      return DateFormat('yyyy-MM-dd').format(time);
    }
  }
}

/// 审批详情页面
class ApprovalDetailPage extends StatefulWidget {
  final ApprovalItem item;

  const ApprovalDetailPage({super.key, required this.item});

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 审批通过
  Future<void> _approve() async {
    try {
      EasyLoading.show(status: '处理中...');

      // TODO: 调用API审批通过
      await Future.delayed(const Duration(seconds: 1));

      EasyLoading.showSuccess('审批通过');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  /// 审批驳回
  Future<void> _reject() async {
    if (_commentController.text.trim().isEmpty) {
      EasyLoading.showError('请填写驳回理由');
      return;
    }

    try {
      EasyLoading.show(status: '处理中...');

      // TODO: 调用API审批驳回
      await Future.delayed(const Duration(seconds: 1));

      EasyLoading.showSuccess('已驳回');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  /// 显示驳回对话框
  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('驳回理由'),
          content: TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '请输入驳回理由...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reject();
              },
              child: const Text(
                '确定驳回',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.item.status == ApprovalStatus.pending;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('审批详情'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 基本信息
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  // 详细内容
                  _buildDetailsCard(),
                  const SizedBox(height: 16),

                  // 审批记录（已审批才显示）
                  if (!isPending) _buildApprovalRecord(),
                ],
              ),
            ),

            // 审批按钮（仅待审批显示）
            if (isPending) _buildApprovalButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息卡片
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIcon(widget.item.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeName(widget.item.type),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.person, '申请人', widget.item.applicant),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.business, '部门', widget.item.department),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.access_time,
            '申请时间',
            DateFormat('yyyy-MM-dd HH:mm').format(widget.item.applyTime),
          ),
        ],
      ),
    );
  }

  /// 构建详细内容卡片
  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '申请内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.item.details.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFieldName(entry.key),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 构建审批记录卡片
  Widget _buildApprovalRecord() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '审批记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.item.status == ApprovalStatus.approved
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.item.status == ApprovalStatus.approved
                      ? Icons.check
                      : Icons.close,
                  color: widget.item.status == ApprovalStatus.approved
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.status == ApprovalStatus.approved
                          ? '审批通过'
                          : '审批驳回',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.item.status == ApprovalStatus.approved
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm')
                          .format(widget.item.approveTime!),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (widget.item.approveComment != null &&
                        widget.item.approveComment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.approveComment!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建审批按钮
  Widget _buildApprovalButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _showRejectDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '驳回',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _approve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  '通过',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建类型图标
  Widget _buildTypeIcon(ApprovalType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ApprovalType.leave:
        icon = Icons.event_busy;
        color = Colors.orange;
        break;
      case ApprovalType.weekly:
        icon = Icons.calendar_view_week;
        color = Colors.blue;
        break;
      case ApprovalType.monthly:
        icon = Icons.calendar_month;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 32,
        color: color,
      ),
    );
  }

  /// 获取类型名称
  String _getTypeName(ApprovalType type) {
    switch (type) {
      case ApprovalType.leave:
        return '请假申请';
      case ApprovalType.weekly:
        return '周报审批';
      case ApprovalType.monthly:
        return '月报审批';
    }
  }

  /// 获取字段名称
  String _getFieldName(String key) {
    const fieldNames = {
      'leaveType': '请假类型',
      'startDate': '开始日期',
      'endDate': '结束日期',
      'days': '请假天数',
      'reason': '请假原因',
      'weekNumber': '周数',
      'dateRange': '日期范围',
      'thisWeek': '本周工作',
      'nextWeek': '下周计划',
      'month': '月份',
      'summary': '工作概述',
      'achievements': '主要成果',
    };
    return fieldNames[key] ?? key;
  }
}

/// 审批类型
enum ApprovalType {
  leave,   // 请假
  weekly,  // 周报
  monthly, // 月报
}

/// 审批状态
enum ApprovalStatus {
  pending,  // 待审批
  approved, // 已通过
  rejected, // 已驳回
}

/// 审批事项模型
class ApprovalItem {
  final int id;
  final ApprovalType type;
  final String title;
  final String applicant;
  final String department;
  final String content;
  final DateTime applyTime;
  final ApprovalStatus status;
  final DateTime? approveTime;
  final String? approveComment;
  final Map<String, String> details;

  ApprovalItem({
    required this.id,
    required this.type,
    required this.title,
    required this.applicant,
    required this.department,
    required this.content,
    required this.applyTime,
    required this.status,
    this.approveTime,
    this.approveComment,
    required this.details,
  });
}
