import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:package_im/services/api_service.dart';
import 'package:package_im/models/pending_task.dart';

/// 周报详情页面
class WeeklyReportDetailPage extends StatefulWidget {
  final int reportId;
  final PendingTask taskData;

  const WeeklyReportDetailPage({
    super.key,
    required this.reportId,
    required this.taskData,
  });

  @override
  State<WeeklyReportDetailPage> createState() => _WeeklyReportDetailPageState();
}

class _WeeklyReportDetailPageState extends State<WeeklyReportDetailPage> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('周报详情'),
        centerTitle: true,
      ),
      body: _buildContent(),
      // 如果是待审批状态，显示审批按钮
      bottomNavigationBar: widget.taskData.status == TaskStatus.PENDING
          ? _buildApprovalButtons()
          : null,
    );
  }

  /// 构建内容
  Widget _buildContent() {
    final task = widget.taskData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          _buildStatusCard(task),
          const SizedBox(height: 16),
          
          // 提交人信息
          _buildInfoCard(
            title: '提交人信息',
            icon: Icons.person,
            children: [
              _buildInfoRow('姓名', task.applicantName),
              _buildInfoRow('部门', task.departmentName),
              _buildInfoRow('提交时间', _formatDateTime(task.createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          
          // 周报信息
          _buildInfoCard(
            title: '周报信息',
            icon: Icons.calendar_view_week,
            children: [
              _buildInfoRow('周报标题', task.title),
              _buildInfoRow('描述', task.description),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard(PendingTask task) {
    final statusColor = task.status.color;
    final statusIcon = task.status == TaskStatus.PENDING 
        ? Icons.pending 
        : task.status == TaskStatus.APPROVED 
            ? Icons.check_circle 
            : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor,
            statusColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusIcon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前状态',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.statusDescription,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      return '-';
    }
  }

  /// 构建审批按钮
  Widget _buildApprovalButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 驳回按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showApprovalDialog(isApprove: false),
                icon: const Icon(Icons.close),
                label: const Text(
                  '驳回',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 通过按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showApprovalDialog(isApprove: true),
                icon: const Icon(Icons.check),
                label: const Text(
                  '通过',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示审批对话框
  void _showApprovalDialog({required bool isApprove}) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isApprove ? '审批通过' : '驳回周报'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? '确认通过此周报吗？'
                    : '确认驳回此周报吗？',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '审批意见${isApprove ? '（可选）' : ''}',
                  hintText: isApprove ? '请输入审批意见' : '请说明驳回原因',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final comment = commentController.text.trim();
                
                // 如果是驳回，必须填写原因
                if (!isApprove && comment.isEmpty) {
                  EasyLoading.showError('请说明驳回原因');
                  return;
                }
                
                Navigator.pop(context);
                _handleApproval(
                  isApprove: isApprove,
                  comment: comment.isNotEmpty ? comment : (isApprove ? '同意通过' : ''),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isApprove ? '确认通过' : '确认驳回'),
            ),
          ],
        );
      },
    );
  }

  /// 处理审批
  Future<void> _handleApproval({
    required bool isApprove,
    required String comment,
  }) async {
    try {
      EasyLoading.show(status: '提交中...');

      final response = await _apiService.approveWeeklyReport(
        reportId: widget.reportId,
        result: isApprove ? 'APPROVED' : 'REJECTED',
        comment: comment,
      );

      EasyLoading.dismiss();

      if (response.success) {
        EasyLoading.showSuccess(isApprove ? '审批通过' : '已驳回');
        
        // 延迟后返回并通知刷新
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context, true); // 返回 true 表示需要刷新
          }
        });
      } else {
        EasyLoading.showError(response.message);
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('操作失败: $e');
    }
  }
}

