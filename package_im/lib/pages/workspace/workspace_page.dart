import 'package:flutter/material.dart';
import 'leave_page.dart';
import 'weekly_report_page.dart';
import 'monthly_report_page.dart';
import 'approval_page.dart';
import 'organization_page.dart';

/// 工作台
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  // 功能入口列表
  final List<Map<String, dynamic>> _workspaceItems = [
    {
      'icon': Icons.event_busy,
      'label': '请假',
      'color': Colors.orange,
      'page': const LeavePage(),
    },
    {
      'icon': Icons.calendar_view_week,
      'label': '周报',
      'color': Colors.blue,
      'page': const WeeklyReportPage(),
    },
    {
      'icon': Icons.calendar_month,
      'label': '月报',
      'color': Colors.green,
      'page': const MonthlyReportPage(),
    },
    {
      'icon': Icons.approval,
      'label': '审批',
      'color': Colors.purple,
      'page': const ApprovalPage(),
    },
    {
      'icon': Icons.account_tree,
      'label': '组织架构',
      'color': Colors.teal,
      'page': const OrganizationPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工作台'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: _workspaceItems.length,
          itemBuilder: (context, index) {
            final item = _workspaceItems[index];
            return _buildWorkspaceItem(
              icon: item['icon'],
              label: item['label'],
              color: item['color'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => item['page']),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 构建工作台功能入口
  Widget _buildWorkspaceItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

