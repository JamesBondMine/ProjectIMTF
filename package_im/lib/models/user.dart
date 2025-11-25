/// 用户模型
class User {
  final int id;
  final String username;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String? phone;
  final String status;
  final String userType;
  final bool isGuest;
  final String createdAt;
  final String updatedAt;
  final bool? isFriend; // 是否为好友（搜索用户时返回）
  final String? employeeNo; // 工号
  final String? entryDate; // 入职日期
  final int? managerId; // 上级主管ID
  final String? managerName; // 上级主管姓名
  final int? primaryDepartmentId; // 主部门ID
  final String? primaryDepartmentName; // 主部门名称

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    this.phone,
    required this.status,
    required this.userType,
    required this.isGuest,
    required this.createdAt,
    required this.updatedAt,
    this.isFriend,
    this.employeeNo,
    this.entryDate,
    this.managerId,
    this.managerName,
    this.primaryDepartmentId,
    this.primaryDepartmentName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      phone: json['phone'],
      status: json['status'] ?? '',
      userType: json['userType'] ?? '',
      isGuest: json['isGuest'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isFriend: json['isFriend'],
      employeeNo: json['employeeNo'],
      entryDate: json['entryDate'],
      managerId: json['managerId'],
      managerName: json['managerName'],
      primaryDepartmentId: json['primaryDepartmentId'],
      primaryDepartmentName: json['primaryDepartmentName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'status': status,
      'userType': userType,
      'isGuest': isGuest,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (isFriend != null) 'isFriend': isFriend,
      if (employeeNo != null) 'employeeNo': employeeNo,
      if (entryDate != null) 'entryDate': entryDate,
      if (managerId != null) 'managerId': managerId,
      if (managerName != null) 'managerName': managerName,
      if (primaryDepartmentId != null) 'primaryDepartmentId': primaryDepartmentId,
      if (primaryDepartmentName != null) 'primaryDepartmentName': primaryDepartmentName,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, nickname: $nickname}';
  }
}

