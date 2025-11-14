/// 统一的API响应模型
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final bool success;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.success,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? json['msg'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      success: json['success'] ?? (json['code'] == 200 || json['code'] == 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'data': data,
      'success': success,
    };
  }

  @override
  String toString() {
    return 'ApiResponse{code: $code, message: $message, data: $data, success: $success}';
  }
}

/// 分页响应模型
class PageResponse<T> {
  final int total;
  final int page;
  final int pageSize;
  final List<T> list;

  PageResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.list,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PageResponse(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      list: (json['list'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item))
              .toList() ??
          [],
    );
  }
}

