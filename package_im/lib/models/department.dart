import 'package:flutter/material.dart';

/// 部门模型
class Department {
  final int id;
  final String name;
  final String code;
  final int? parentId;
  final String? parentName;
  final int level;
  final int sortOrder;
  final int? leaderId;
  final String? leaderName;
  final String? description;
  final String status;
  final int memberCount;
  final List<Department> children;
  final String? createdAt;
  final String? updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.code,
    this.parentId,
    this.parentName,
    required this.level,
    required this.sortOrder,
    this.leaderId,
    this.leaderName,
    this.description,
    required this.status,
    required this.memberCount,
    this.children = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      parentId: json['parentId'],
      parentName: json['parentName'],
      level: json['level'] ?? 1,
      sortOrder: json['sortOrder'] ?? 0,
      leaderId: json['leaderId'],
      leaderName: json['leaderName'],
      description: json['description'],
      status: json['status'] ?? 'ACTIVE',
      memberCount: json['memberCount'] ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((child) => Department.fromJson(child))
              .toList() ??
          [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'parentId': parentId,
      'parentName': parentName,
      'level': level,
      'sortOrder': sortOrder,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'description': description,
      'status': status,
      'memberCount': memberCount,
      'children': children.map((child) => child.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 获取显示的员工数量文本
  String get employeeCountText {
    return memberCount > 0 ? '$memberCount人' : '0人';
  }

  /// 是否有负责人
  bool get hasLeader {
    return leaderId != null && leaderName != null;
  }

  /// 获取负责人显示文本
  String get leaderDisplayText {
    if (hasLeader) {
      return '负责人: $leaderName';
    }
    return '暂无负责人';
  }

  /// 是否激活状态
  bool get isActive {
    return status == 'ACTIVE';
  }
}

/// 部门成员模型
class DepartmentMember {
  final int id;
  final int userId;
  final String username;
  final String nickname;
  final int departmentId;
  final String departmentName;
  final String position;
  final bool isPrimary;
  final bool isLeader;
  final String joinDate;
  final String? leaveDate;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  DepartmentMember({
    required this.id,
    required this.userId,
    required this.username,
    required this.nickname,
    required this.departmentId,
    required this.departmentName,
    required this.position,
    required this.isPrimary,
    required this.isLeader,
    required this.joinDate,
    this.leaveDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DepartmentMember.fromJson(Map<String, dynamic> json) {
    return DepartmentMember(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      departmentId: json['departmentId'] ?? 0,
      departmentName: json['departmentName'] ?? '',
      position: json['position'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      isLeader: json['isLeader'] ?? false,
      joinDate: json['joinDate'] ?? '',
      leaveDate: json['leaveDate'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'nickname': nickname,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'position': position,
      'isPrimary': isPrimary,
      'isLeader': isLeader,
      'joinDate': joinDate,
      'leaveDate': leaveDate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 获取显示名称（优先显示昵称）
  String get displayName {
    return nickname.isNotEmpty ? nickname : username;
  }

  /// 获取名称首字母（用于头像）
  String get nameInitial {
    return displayName.isNotEmpty ? displayName.substring(0, 1) : '?';
  }

  /// 是否激活状态
  bool get isActive {
    return status == 'ACTIVE';
  }

  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case 'ACTIVE':
        return '在职';
      case 'INACTIVE':
        return '离职';
      default:
        return status;
    }
  }

  /// 获取状态颜色
  Color get statusColor {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF4CAF50);
      case 'INACTIVE':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

