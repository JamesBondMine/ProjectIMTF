/// 周报状态枚举
enum WeeklyReportStatus {
  DRAFT('DRAFT', '草稿'),
  PENDING('PENDING', '待审批'),
  APPROVED('APPROVED', '已通过'),
  REJECTED('REJECTED', '已驳回');

  final String value;
  final String description;

  const WeeklyReportStatus(this.value, this.description);

  static WeeklyReportStatus fromValue(String value) {
    return WeeklyReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => WeeklyReportStatus.DRAFT,
    );
  }
}

/// 周报数据模型
class WeeklyReportModel {
  final int id;
  final int userId;
  final String userName;
  final String departmentName;
  final String title;
  final String startTime;
  final String endTime;
  final String thisWeekContent;
  final String nextWeekPlan;
  final String? remark;
  final String status;
  final String statusDescription;
  final int? approverId;
  final String? approverName;
  final String? approvalTime;
  final String? approvalComment;
  final String createdAt;
  final String updatedAt;

  WeeklyReportModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.departmentName,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.thisWeekContent,
    required this.nextWeekPlan,
    this.remark,
    required this.status,
    required this.statusDescription,
    this.approverId,
    this.approverName,
    this.approvalTime,
    this.approvalComment,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从JSON创建周报对象
  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      departmentName: json['departmentName'] ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      thisWeekContent: json['thisWeekContent'] ?? '',
      nextWeekPlan: json['nextWeekPlan'] ?? '',
      remark: json['remark'],
      status: json['status'] ?? 'DRAFT',
      statusDescription: json['statusDescription'] ?? '',
      approverId: json['approverId'],
      approverName: json['approverName'],
      approvalTime: json['approvalTime'],
      approvalComment: json['approvalComment'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'departmentName': departmentName,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'thisWeekContent': thisWeekContent,
      'nextWeekPlan': nextWeekPlan,
      'remark': remark,
      'status': status,
      'statusDescription': statusDescription,
      'approverId': approverId,
      'approverName': approverName,
      'approvalTime': approvalTime,
      'approvalComment': approvalComment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 获取周报状态枚举
  WeeklyReportStatus get reportStatus {
    return WeeklyReportStatus.fromValue(status);
  }

  /// 是否为草稿
  bool get isDraft => status == 'DRAFT';

  /// 是否待审批
  bool get isPending => status == 'PENDING';

  /// 是否已通过
  bool get isApproved => status == 'APPROVED';

  /// 是否已驳回
  bool get isRejected => status == 'REJECTED';

  /// 获取周数
  int get weekNumber {
    try {
      final date = DateTime.parse(startTime);
      final firstDayOfYear = DateTime(date.year, 1, 1);
      final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
      return (daysSinceFirstDay / 7).floor() + 1;
    } catch (e) {
      return 0;
    }
  }

  /// 获取年份
  int get year {
    try {
      final date = DateTime.parse(startTime);
      return date.year;
    } catch (e) {
      return DateTime.now().year;
    }
  }
}

