import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';

/// 周报页面
class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  final List<WeeklyReport> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// 加载周报列表
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用API获取周报列表
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据
      setState(() {
        _reports.clear();
        _reports.addAll([
          WeeklyReport(
            id: 1,
            weekNumber: 47,
            year: 2024,
            startDate: DateTime(2024, 11, 18),
            endDate: DateTime(2024, 11, 24),
            title: '第47周工作周报',
            status: ReportStatus.approved,
            submitTime: DateTime.now().subtract(const Duration(days: 2)),
          ),
          WeeklyReport(
            id: 2,
            weekNumber: 46,
            year: 2024,
            startDate: DateTime(2024, 11, 11),
            endDate: DateTime(2024, 11, 17),
            title: '第46周工作周报',
            status: ReportStatus.pending,
            submitTime: DateTime.now().subtract(const Duration(days: 9)),
          ),
          WeeklyReport(
            id: 3,
            weekNumber: 45,
            year: 2024,
            startDate: DateTime(2024, 11, 4),
            endDate: DateTime(2024, 11, 10),
            title: '第45周工作周报',
            status: ReportStatus.draft,
            submitTime: null,
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

  /// 新建周报
  void _createReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeeklyReportEditPage(),
      ),
    ).then((result) {
      if (result == true) {
        _loadReports();
      }
    });
  }

  /// 查看/编辑周报
  void _viewReport(WeeklyReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklyReportEditPage(report: report),
      ),
    ).then((result) {
      if (result == true) {
        _loadReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周报'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createReport,
            tooltip: '新建周报',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(_reports[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createReport,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 构建周报卡片
  Widget _buildReportCard(WeeklyReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewReport(report),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_view_week,
                        size: 24,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  report.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(report.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('MM-dd').format(report.startDate)} - ${DateFormat('MM-dd').format(report.endDate)}',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      report.submitTime != null
                          ? Icons.check_circle
                          : Icons.edit,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.submitTime != null
                          ? '提交于 ${_formatTime(report.submitTime!)}'
                          : '草稿',
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

  /// 构建状态标签
  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    String text;

    switch (status) {
      case ReportStatus.draft:
        color = Colors.grey;
        text = '草稿';
        break;
      case ReportStatus.pending:
        color = Colors.orange;
        text = '待审批';
        break;
      case ReportStatus.approved:
        color = Colors.green;
        text = '已通过';
        break;
      case ReportStatus.rejected:
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
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_view_week,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无周报',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角添加按钮创建周报',
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

/// 周报编辑页面
class WeeklyReportEditPage extends StatefulWidget {
  final WeeklyReport? report;

  const WeeklyReportEditPage({super.key, this.report});

  @override
  State<WeeklyReportEditPage> createState() => _WeeklyReportEditPageState();
}

class _WeeklyReportEditPageState extends State<WeeklyReportEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _thisWeekController = TextEditingController();
  final _nextWeekController = TextEditingController();
  final _issuesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.report != null;
    if (_isEditing) {
      _titleController.text = widget.report!.title;
      _startDate = widget.report!.startDate;
      _endDate = widget.report!.endDate;
      // TODO: 加载周报详细内容
    } else {
      // 新建周报，自动设置为当前周
      _autoSetCurrentWeek();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _thisWeekController.dispose();
    _nextWeekController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  /// 自动设置当前周
  void _autoSetCurrentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    setState(() {
      _startDate = DateTime(monday.year, monday.month, monday.day);
      _endDate = DateTime(sunday.year, sunday.month, sunday.day);
      _titleController.text = _generateTitle();
    });
  }

  /// 生成标题
  String _generateTitle() {
    if (_startDate == null) return '';
    final weekNumber = _getWeekNumber(_startDate!);
    return '第${weekNumber}周工作周报';
  }

  /// 获取周数
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }

  /// 选择日期
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 6));
          }
        } else {
          _endDate = picked;
        }
        _titleController.text = _generateTitle();
      });
    }
  }

  /// 保存草稿
  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      EasyLoading.show(status: '保存中...');

      // TODO: 调用API保存草稿
      await Future.delayed(const Duration(seconds: 1));

      EasyLoading.showSuccess('草稿已保存');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      EasyLoading.showError('保存失败: $e');
    }
  }

  /// 提交周报
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_thisWeekController.text.trim().isEmpty) {
      EasyLoading.showError('请填写本周工作内容');
      return;
    }

    if (_nextWeekController.text.trim().isEmpty) {
      EasyLoading.showError('请填写下周计划');
      return;
    }

    try {
      EasyLoading.show(status: '提交中...');

      // TODO: 调用API提交周报
      await Future.delayed(const Duration(seconds: 1));

      EasyLoading.showSuccess('周报已提交');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      EasyLoading.showError('提交失败: $e');
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
          title: Text(_isEditing ? '编辑周报' : '新建周报'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _saveDraft,
              child: const Text(
                '保存草稿',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 标题
              _buildSectionTitle('周报标题'),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '请输入周报标题',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入周报标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 周期选择
              _buildSectionTitle('周报周期'),
              _buildDateRangeSelector(),
              const SizedBox(height: 24),

              // 本周工作
              _buildSectionTitle('本周工作内容'),
              _buildTextArea(
                controller: _thisWeekController,
                hintText: '请详细描述本周完成的工作内容...\n例如：\n1. 完成XXX功能开发\n2. 修复XXX问题\n3. 参与XXX会议',
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // 下周计划
              _buildSectionTitle('下周工作计划'),
              _buildTextArea(
                controller: _nextWeekController,
                hintText: '请描述下周的工作计划...\n例如：\n1. 开始XXX功能开发\n2. 完成XXX文档编写\n3. 进行XXX测试',
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // 问题与建议
              _buildSectionTitle('问题与建议（选填）'),
              _buildTextArea(
                controller: _issuesController,
                hintText: '请描述工作中遇到的问题和建议...',
                maxLines: 6,
              ),
              const SizedBox(height: 32),

              // 提交按钮
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 构建日期范围选择器
  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(
            label: '开始日期',
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateCard(
            label: '结束日期',
            date: _endDate,
            onTap: () => _selectDate(context, false),
          ),
        ),
      ],
    );
  }

  /// 构建日期卡片
  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : '选择日期',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: date != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文本输入区域
  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /// 构建提交按钮
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          '提交周报',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 周报状态
enum ReportStatus {
  draft,    // 草稿
  pending,  // 待审批
  approved, // 已通过
  rejected, // 已驳回
}

/// 周报模型
class WeeklyReport {
  final int id;
  final int weekNumber;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final ReportStatus status;
  final DateTime? submitTime;

  WeeklyReport({
    required this.id,
    required this.weekNumber,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.status,
    this.submitTime,
  });
}
