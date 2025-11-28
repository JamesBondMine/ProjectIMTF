import 'package:flutter/material.dart';

/// 待办任务类型
enum TaskType {
  LEAVE,      // 请假
  WEEKLY_REPORT,     // 周报
  MONTHLY_REPORT,    // 月报
  APPROVAL,   // 审批
}

/// 待办任务状态
enum TaskStatus {
  PENDING,    // 待审批
  APPROVED,   // 已通过
  REJECTED,   // 已驳回
}

/// 待办任务扩展
extension TaskTypeExtension on TaskType {
  String get value {
    return name;
  }
  
  String get description {
    switch (this) {
      case TaskType.LEAVE:
        return '请假';
      case TaskType.WEEKLY_REPORT:
        return '周报';
      case TaskType.MONTHLY_REPORT:
        return '月报';
      case TaskType.APPROVAL:
        return '审批';
    }
  }
  
  IconData get icon {
    switch (this) {
      case TaskType.LEAVE:
        return Icons.event_busy;
      case TaskType.WEEKLY_REPORT:
        return Icons.calendar_view_week;
      case TaskType.MONTHLY_REPORT:
        return Icons.calendar_month;
      case TaskType.APPROVAL:
        return Icons.approval;
    }
  }
  
  Color get color {
    switch (this) {
      case TaskType.LEAVE:
        return Colors.orange;
      case TaskType.WEEKLY_REPORT:
        return Colors.blue;
      case TaskType.MONTHLY_REPORT:
        return Colors.green;
      case TaskType.APPROVAL:
        return Colors.purple;
    }
  }
  
  static TaskType? fromString(String? value) {
    if (value == null) return null;
    try {
      return TaskType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskType.APPROVAL,
      );
    } catch (e) {
      return null;
    }
  }
}

extension TaskStatusExtension on TaskStatus {
  String get value {
    return name;
  }
  
  String get description {
    switch (this) {
      case TaskStatus.PENDING:
        return '待审批';
      case TaskStatus.APPROVED:
        return '已通过';
      case TaskStatus.REJECTED:
        return '已驳回';
    }
  }
  
  Color get color {
    switch (this) {
      case TaskStatus.PENDING:
        return Colors.orange;
      case TaskStatus.APPROVED:
        return Colors.green;
      case TaskStatus.REJECTED:
        return Colors.red;
    }
  }
  
  static TaskStatus? fromString(String? value) {
    if (value == null) return null;
    try {
      return TaskStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskStatus.PENDING,
      );
    } catch (e) {
      return null;
    }
  }
}

/// 待办任务模型
class PendingTask {
  final int id;
  final TaskType taskType;
  final String taskTypeDescription;
  final int taskId;
  final String title;
  final String applicantName;
  final String departmentName;
  final String description;
  final TaskStatus status;
  final String statusDescription;
  final DateTime createdAt;

  PendingTask({
    required this.id,
    required this.taskType,
    required this.taskTypeDescription,
    required this.taskId,
    required this.title,
    required this.applicantName,
    required this.departmentName,
    required this.description,
    required this.status,
    required this.statusDescription,
    required this.createdAt,
  });

  factory PendingTask.fromJson(Map<String, dynamic> json) {
    return PendingTask(
      id: json['id'] as int,
      taskType: TaskTypeExtension.fromString(json['taskType'] as String?) ?? TaskType.APPROVAL,
      taskTypeDescription: json['taskTypeDescription'] as String? ?? '',
      taskId: json['taskId'] as int,
      title: json['title'] as String? ?? '',
      applicantName: json['applicantName'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: TaskStatusExtension.fromString(json['status'] as String?) ?? TaskStatus.PENDING,
      statusDescription: json['statusDescription'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskType': taskType.value,
      'taskTypeDescription': taskTypeDescription,
      'taskId': taskId,
      'title': title,
      'applicantName': applicantName,
      'departmentName': departmentName,
      'description': description,
      'status': status.value,
      'statusDescription': statusDescription,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 是否紧急（创建时间在2小时内）
  bool get isUrgent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 2;
  }

  /// 是否已处理
  bool get isDone {
    return status == TaskStatus.APPROVED || status == TaskStatus.REJECTED;
  }

  /// 是否已通过
  bool get isApproved {
    return status == TaskStatus.APPROVED;
  }
}

/// 分页数据模型
class PageData<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  PageData({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageData(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'content': content.map((item) => toJsonT(item)).toList(),
      'totalElements': totalElements,
      'totalPages': totalPages,
      'number': number,
      'size': size,
    };
  }
}

