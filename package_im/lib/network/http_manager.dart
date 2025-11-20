import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'api_config.dart';
import 'api_response.dart';

/// HTTP请求管理类
class HttpManager {
  static final HttpManager _instance = HttpManager._internal();
  factory HttpManager() => _instance;

  late Dio _dio;
  String? _token;

  HttpManager._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConfig.sendTimeout),
      headers: ApiConfig.headers,
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));

    // 添加日志拦截器（开发环境）
    if (ApiConfig.enableLog) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }
  }

  /// 设置Token
  void setToken(String token) {
    _token = token;
  }

  /// 清除Token
  void clearToken() {
    _token = null;
  }

  /// 获取Token
  String? getToken() {
    return _token;
  }

  /// 请求拦截器
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 添加Token到请求头
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }

  /// 响应拦截器
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  /// 错误拦截器
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    String errorMessage = _handleError(error);
    
    // 显示错误提示
    if (ApiConfig.enableLog) {
      EasyLoading.showError(errorMessage);
    }
    
    handler.next(error);
  }

  /// 处理错误信息
  String _handleError(DioException error) {
    // 优先尝试从响应体中提取具体错误信息
    if (error.response?.data != null) {
      try {
        final data = error.response!.data;
        // 如果响应是 Map，尝试提取 msg 或 message 字段
        if (data is Map<String, dynamic>) {
          final msg = data['msg'] ?? data['message'];
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
      } catch (e) {
        debugPrint('解析错误消息失败: $e');
      }
    }
    
    // 如果无法从响应体提取，使用默认错误处理
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '请求超时，请稍后重试';
      case DioExceptionType.receiveTimeout:
        return '响应超时，请稍后重试';
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络';
      default:
        return '网络请求失败: ${error.message}';
    }
  }

  /// 处理HTTP错误状态码
  String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '拒绝访问';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      case 504:
        return '网关超时';
      default:
        return '请求失败($statusCode)';
    }
  }

  /// GET请求
  /// 
  /// [path] 请求路径
  /// [queryParameters] 查询参数
  /// [options] 请求配置
  /// [showLoading] 是否显示加载提示
  /// [fromJson] JSON转换函数
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool showLoading = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '加载中...');
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// POST请求
  /// 
  /// [path] 请求路径
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [options] 请求配置
  /// [showLoading] 是否显示加载提示
  /// [fromJson] JSON转换函数
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool showLoading = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '提交中...');
      }

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// PUT请求
  /// 
  /// [path] 请求路径
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [options] 请求配置
  /// [showLoading] 是否显示加载提示
  /// [fromJson] JSON转换函数
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool showLoading = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '更新中...');
      }

      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// DELETE请求
  /// 
  /// [path] 请求路径
  /// [data] 请求数据
  /// [queryParameters] 查询参数
  /// [options] 请求配置
  /// [showLoading] 是否显示加载提示
  /// [fromJson] JSON转换函数
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool showLoading = false,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '删除中...');
      }

      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// 文件上传
  /// 
  /// [path] 上传路径
  /// [file] 要上传的文件
  /// [fileName] 文件名（可选）
  /// [data] 额外的表单数据
  /// [onSendProgress] 上传进度回调
  /// [showLoading] 是否显示加载提示
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    File file, {
    String? fileName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    bool showLoading = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '上传中...0%');
      }

      // 创建FormData
      String name = fileName ?? file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: name),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: (sent, total) {
          if (showLoading) {
            double progress = (sent / total * 100);
            EasyLoading.showProgress(
              progress / 100,
              status: '上传中...${progress.toStringAsFixed(0)}%',
            );
          }
          onSendProgress?.call(sent, total);
        },
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// 批量文件上传
  /// 
  /// [path] 上传路径
  /// [files] 要上传的文件列表
  /// [data] 额外的表单数据
  /// [onSendProgress] 上传进度回调
  /// [showLoading] 是否显示加载提示
  Future<ApiResponse<T>> uploadFiles<T>(
    String path,
    List<File> files, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    bool showLoading = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '上传中...0%');
      }

      // 创建FormData
      List<MultipartFile> multipartFiles = [];
      for (var file in files) {
        multipartFiles.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }

      FormData formData = FormData.fromMap({
        'files': multipartFiles,
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: (sent, total) {
          if (showLoading) {
            double progress = (sent / total * 100);
            EasyLoading.showProgress(
              progress / 100,
              status: '上传中...${progress.toStringAsFixed(0)}%',
            );
          }
          onSendProgress?.call(sent, total);
        },
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// 下载文件
  /// 
  /// [urlPath] 文件URL
  /// [savePath] 保存路径
  /// [onReceiveProgress] 下载进度回调
  /// [showLoading] 是否显示加载提示
  Future<void> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        EasyLoading.show(status: '下载中...0%');
      }

      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (showLoading) {
              debugPrint('下载进度:   $total');
              debugPrint('下载进度1: $received');

              double progress = (received / total * 100);
              EasyLoading.showProgress(
                progress / 100,
                status: '下载中...${progress.toStringAsFixed(0)}%',
              );
            }
            onReceiveProgress?.call(received, total);
          }
        },
      );

      if (showLoading) {
        EasyLoading.dismiss();
      }
    } catch (e) {
      if (showLoading) {
        EasyLoading.dismiss();
      }
      rethrow;
    }
  }

  /// 取消请求
  void cancelRequests({CancelToken? cancelToken}) {
    cancelToken?.cancel('请求已取消');
  }
}

