import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:package_im/models/leave.dart';
import 'package:package_im/services/api_service.dart';

/// 请假详情页面
class LeaveDetailPage extends StatefulWidget {
  final int leaveId;

  const LeaveDetailPage({
    super.key,
    required this.leaveId,
  });

  @override
  State<LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {
  final ApiService _apiService = ApiService();
  LeaveApplication? _leaveDetail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLeaveDetail();
  }

  /// 加载请假详情
  Future<void> _loadLeaveDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getLeaveDetail(widget.leaveId);

      if (response.success && response.data != null) {
        setState(() {
          _leaveDetail = LeaveApplication.fromJson(response.data!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          EasyLoading.showError(response.message);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        EasyLoading.showError('加载失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('请假详情'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaveDetail == null
              ? _buildEmptyState()
              : _buildContent(),
      // 如果是待审批状态，显示审批按钮
      bottomNavigationBar: _leaveDetail != null && _leaveDetail!.status == 'PENDING'
          ? _buildApprovalButtons()
          : null,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadLeaveDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    final leave = _leaveDetail!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          _buildStatusCard(leave),
          const SizedBox(height: 16),
          
          // 申请人信息
          _buildInfoCard(
            title: '申请人信息',
            icon: Icons.person,
            children: [
              _buildInfoRow('姓名', leave.userName),
              _buildInfoRow('部门', leave.departmentName),
              _buildInfoRow('申请时间', _formatDateTime(leave.createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          
          // 请假信息
          _buildInfoCard(
            title: '请假信息',
            icon: Icons.event_busy,
            children: [
              _buildInfoRow('请假类型', leave.leaveTypeDescription),
              _buildInfoRow('开始时间', _formatDateTime(leave.startTime)),
              _buildInfoRow('结束时间', _formatDateTime(leave.endTime)),
              _buildInfoRow('请假天数', '${leave.days}天'),
              const Divider(height: 24),
              _buildReasonSection(leave.reason),
            ],
          ),
          const SizedBox(height: 16),
          
          // 审批信息
          if (leave.approverName != null || leave.status != 'PENDING')
            _buildInfoCard(
              title: '审批信息',
              icon: Icons.approval,
              children: [
                if (leave.approverName != null)
                  _buildInfoRow('审批人', leave.approverName!),
                if (leave.approvalTime != null)
                  _buildInfoRow('审批时间', _formatDateTime(leave.approvalTime)),
                if (leave.approvalComment != null && leave.approvalComment!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildCommentSection(leave.approvalComment!),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard(LeaveApplication leave) {
    Color statusColor;
    IconData statusIcon;
    
    switch (leave.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'APPROVED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'CANCELLED':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

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
                  leave.statusDescription,
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

  /// 构建请假原因部分
  Widget _buildReasonSection(String reason) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '请假原因',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            reason,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建审批意见部分
  Widget _buildCommentSection(String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '审批意见',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            comment,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化日期时间
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
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
          title: Text(isApprove ? '审批通过' : '驳回申请'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? '确认通过此请假申请吗？'
                    : '确认驳回此请假申请吗？',
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

      final response = await _apiService.approveLeave(
        leaveId: widget.leaveId,
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

