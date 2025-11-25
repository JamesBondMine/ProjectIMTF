/// 请假类型枚举
enum LeaveType {
  personalLeave('PERSONAL_LEAVE', '事假'),
  sickLeave('SICK_LEAVE', '病假'),
  annualLeave('ANNUAL_LEAVE', '年假'),
  lieuLeave('LIEU_LEAVE', '调休'),
  marriageLeave('MARRIAGE_LEAVE', '婚假'),
  maternityLeave('MATERNITY_LEAVE', '产假'),
  paternityLeave('PATERNITY_LEAVE', '陪产假'),
  other('OTHER', '其他');

  final String value;
  final String description;
  
  const LeaveType(this.value, this.description);

  static LeaveType fromDescription(String description) {
    return LeaveType.values.firstWhere(
      (type) => type.description == description,
      orElse: () => LeaveType.other,
    );
  }

  static LeaveType fromValue(String value) {
    return LeaveType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LeaveType.other,
    );
  }
}

/// 请假状态枚举
enum LeaveStatus {
  pending('PENDING', '待审批'),
  approved('APPROVED', '已通过'),
  rejected('REJECTED', '已驳回'),
  cancelled('CANCELLED', '已撤销');

  final String value;
  final String description;
  
  const LeaveStatus(this.value, this.description);

  static LeaveStatus fromValue(String value) {
    return LeaveStatus.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LeaveStatus.pending,
    );
  }
}

/// 请假申请模型
class LeaveApplication {
  final int id;
  final int userId;
  final String userName;
  final String departmentName;
  final String leaveType;
  final String leaveTypeDescription;
  final String startTime;
  final String endTime;
  final double days;
  final String reason;
  final String status;
  final String statusDescription;
  final String? approverName;
  final String? approvalComment;
  final String? approvalTime;
  final String? createdAt;
  final String? updatedAt;

  LeaveApplication({
    required this.id,
    required this.userId,
    required this.userName,
    required this.departmentName,
    required this.leaveType,
    required this.leaveTypeDescription,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.reason,
    required this.status,
    required this.statusDescription,
    this.approverName,
    this.approvalComment,
    this.approvalTime,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      departmentName: json['departmentName'] ?? '',
      leaveType: json['leaveType'] ?? '',
      leaveTypeDescription: json['leaveTypeDescription'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      days: (json['days'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      statusDescription: json['statusDescription'] ?? '',
      approverName: json['approverName'],
      approvalComment: json['approvalComment'],
      approvalTime: json['approvalTime'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'departmentName': departmentName,
      'leaveType': leaveType,
      'leaveTypeDescription': leaveTypeDescription,
      'startTime': startTime,
      'endTime': endTime,
      'days': days,
      'reason': reason,
      'status': status,
      'statusDescription': statusDescription,
      if (approverName != null) 'approverName': approverName,
      if (approvalComment != null) 'approvalComment': approvalComment,
      if (approvalTime != null) 'approvalTime': approvalTime,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  /// 获取状态枚举
  LeaveStatus get statusEnum => LeaveStatus.fromValue(status);

  /// 获取类型枚举
  LeaveType get typeEnum => LeaveType.fromValue(leaveType);
}

