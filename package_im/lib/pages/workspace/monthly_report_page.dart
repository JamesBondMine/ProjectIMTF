import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';

/// 月报页面
class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final List<MonthlyReport> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// 加载月报列表
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 调用API获取月报列表
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据
      setState(() {
        _reports.clear();
        _reports.addAll([
          MonthlyReport(
            id: 1,
            month: 11,
            year: 2024,
            title: '2024年11月工作月报',
            status: ReportStatus.approved,
            submitTime: DateTime.now().subtract(const Duration(days: 5)),
          ),
          MonthlyReport(
            id: 2,
            month: 10,
            year: 2024,
            title: '2024年10月工作月报',
            status: ReportStatus.pending,
            submitTime: DateTime.now().subtract(const Duration(days: 25)),
          ),
          MonthlyReport(
            id: 3,
            month: 9,
            year: 2024,
            title: '2024年9月工作月报',
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

  /// 新建月报
  void _createReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonthlyReportEditPage(),
      ),
    ).then((result) {
      if (result == true) {
        _loadReports();
      }
    });
  }

  /// 查看/编辑月报
  void _viewReport(MonthlyReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlyReportEditPage(report: report),
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
        title: const Text('月报'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createReport,
            tooltip: '新建月报',
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

  /// 构建月报卡片
  Widget _buildReportCard(MonthlyReport report) {
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        size: 24,
                        color: Colors.green,
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
                            '${report.year}年${report.month}月',
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
            Icons.calendar_month,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无月报',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角添加按钮创建月报',
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

/// 月报编辑页面
class MonthlyReportEditPage extends StatefulWidget {
  final MonthlyReport? report;

  const MonthlyReportEditPage({super.key, this.report});

  @override
  State<MonthlyReportEditPage> createState() => _MonthlyReportEditPageState();
}

class _MonthlyReportEditPageState extends State<MonthlyReportEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _dataController = TextEditingController();
  final _nextMonthController = TextEditingController();
  final _issuesController = TextEditingController();

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.report != null;
    if (_isEditing) {
      _titleController.text = widget.report!.title;
      _selectedYear = widget.report!.year;
      _selectedMonth = widget.report!.month;
      // TODO: 加载月报详细内容
    } else {
      // 新建月报，自动设置为上个月
      _autoSetLastMonth();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _achievementsController.dispose();
    _dataController.dispose();
    _nextMonthController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  /// 自动设置为上个月
  void _autoSetLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    setState(() {
      _selectedYear = lastMonth.year;
      _selectedMonth = lastMonth.month;
      _titleController.text = _generateTitle();
    });
  }

  /// 生成标题
  String _generateTitle() {
    return '$_selectedYear年$_selectedMonth月工作月报';
  }

  /// 选择年月
  Future<void> _selectYearMonth(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempYear = _selectedYear;
        int tempMonth = _selectedMonth;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择年月'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 年份选择
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            tempYear--;
                          });
                        },
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '$tempYear年',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 月份选择
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected = month == tempMonth;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            tempMonth = month;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${month}月',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
                    this.setState(() {
                      _selectedYear = tempYear;
                      _selectedMonth = tempMonth;
                      _titleController.text = _generateTitle();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
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

  /// 提交月报
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_summaryController.text.trim().isEmpty) {
      EasyLoading.showError('请填写工作概述');
      return;
    }

    if (_achievementsController.text.trim().isEmpty) {
      EasyLoading.showError('请填写主要成果');
      return;
    }

    try {
      EasyLoading.show(status: '提交中...');

      // TODO: 调用API提交月报
      await Future.delayed(const Duration(seconds: 1));

      EasyLoading.showSuccess('月报已提交');
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
          title: Text(_isEditing ? '编辑月报' : '新建月报'),
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
              _buildSectionTitle('月报标题'),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '请输入月报标题',
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
                    return '请输入月报标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 月份选择
              _buildSectionTitle('报告月份'),
              _buildYearMonthSelector(),
              const SizedBox(height: 24),

              // 工作概述
              _buildSectionTitle('工作概述'),
              _buildTextArea(
                controller: _summaryController,
                hintText: '请概述本月整体工作情况...\n例如：\n本月主要完成了XXX项目的开发工作，参与了XXX会议，协助处理了XXX问题...',
                maxLines: 6,
              ),
              const SizedBox(height: 24),

              // 主要成果
              _buildSectionTitle('主要成果'),
              _buildTextArea(
                controller: _achievementsController,
                hintText: '请列举本月的主要工作成果...\n例如：\n1. 完成XXX功能模块开发\n2. 优化XXX性能提升X%\n3. 解决XXX关键问题',
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // 数据统计
              _buildSectionTitle('数据统计（选填）'),
              _buildTextArea(
                controller: _dataController,
                hintText: '请填写相关数据指标...\n例如：\n- 完成需求：X个\n- 修复Bug：X个\n- 代码提交：X次\n- 工作时长：X小时',
                maxLines: 6,
              ),
              const SizedBox(height: 24),

              // 下月计划
              _buildSectionTitle('下月计划'),
              _buildTextArea(
                controller: _nextMonthController,
                hintText: '请描述下月的工作计划...\n例如：\n1. 启动XXX新项目\n2. 完成XXX功能优化\n3. 学习XXX新技术',
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // 问题与建议
              _buildSectionTitle('问题与建议（选填）'),
              _buildTextArea(
                controller: _issuesController,
                hintText: '请描述工作中遇到的问题和改进建议...',
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

  /// 构建年月选择器
  Widget _buildYearMonthSelector() {
    return InkWell(
      onTap: () => _selectYearMonth(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              '$_selectedYear年$_selectedMonth月',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
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
          '提交月报',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 月报状态
enum ReportStatus {
  draft,    // 草稿
  pending,  // 待审批
  approved, // 已通过
  rejected, // 已驳回
}

/// 月报模型
class MonthlyReport {
  final int id;
  final int month;
  final int year;
  final String title;
  final ReportStatus status;
  final DateTime? submitTime;

  MonthlyReport({
    required this.id,
    required this.month,
    required this.year,
    required this.title,
    required this.status,
    this.submitTime,
  });
}
