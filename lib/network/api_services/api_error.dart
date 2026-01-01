import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../data/token_storage.dart';
import '../../../models/api_response_model.dart';

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  server,
  cancelled,
  parsing,
  unknown,
  badRequest,
  forbidden,
  notFound,
  rateLimit,
  serverUnavailable,
}

class ApiError {
  final String message;
  final int? code;
  final ApiErrorType type;
  final ApiResponseModel? response;

  ApiError({
    required this.message,
    this.code,
    required this.type,
    this.response,
  });
}

class ErrorHandler {
  static ApiError handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException) {
      return ApiError(
        message: "Bad response format",
        type: ApiErrorType.parsing,
      );
    } else {
      return ApiError(
        message: "Unexpected error: $error",
        type: ApiErrorType.unknown,
      );
    }
  }

  static ApiError _handleDioError(DioException error) {
    String defaultMsg = "An error occurred";
    ApiErrorType type = ApiErrorType.unknown;
    int? code = error.response?.statusCode;
    if (error.response != null) {
      return parseResponse(error.response!);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        defaultMsg =
            "Request timed out – Please check your internet connection.";
        type = ApiErrorType.timeout;
        break;
      case DioExceptionType.badCertificate:
        defaultMsg = "Security Error – Invalid SSL certificate.";
        type = ApiErrorType.network;
        break;
      case DioExceptionType.badResponse:
        defaultMsg = "Server Error – Invalid response received.";
        type = ApiErrorType.parsing;
        break;
      case DioExceptionType.cancel:
        defaultMsg = "Request cancelled";
        type = ApiErrorType.cancelled;
        break;
      case DioExceptionType.connectionError:
        defaultMsg = "No internet connection – Unable to reach the server.";
        type = ApiErrorType.network;
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          defaultMsg = "No internet connection – Please check your network.";
          type = ApiErrorType.network;
        } else if (error.error is FormatException) {
          defaultMsg = "Data Error – specific format exception.";
          type = ApiErrorType.parsing;
        } else {
          defaultMsg = "Unknown error: ${error.message}";
          type = ApiErrorType.unknown;
        }
        break;
    }
    return ApiError(message: defaultMsg, type: type, code: code);
  }

  static ApiError parseResponse(Response res) {
    String? serverMessage;
    ApiResponseModel? errorModel;
    final data = res.data;

    // 1. Try key-based extraction first (most robust)
    try {
      if (data is Map<String, dynamic>) {
        serverMessage = data['message'] ?? data['error'];
      } else if (data is String) {
        // Try parsing string as JSON
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            serverMessage = decoded['message'] ?? decoded['error'];
          }
        } catch (_) {
          // If not JSON, use the string itself if it's short enough to be a message
          if (data.length < 200) serverMessage = data;
        }
      }
    } catch (_) {}

    // 2. Try strict Model parsing (for structured errors)
    if (res.statusCode != 500) {
      try {
        if (data != null) {
          final Map<String, dynamic> decodedData = data is String
              ? jsonDecode(data)
              : data as Map<String, dynamic>;
          errorModel = ApiResponseModel.fromJson(decodedData);
          // If model has a message, it takes precedence
          if (errorModel.message.isNotEmpty) {
            serverMessage = errorModel.message;
          }
        }
      } catch (_) {}
    }

    _authGuard(res.statusCode);

    ApiErrorType type;
    String statusMessage;

    switch (res.statusCode) {
      case 400:
        statusMessage = 'Bad Request';
        type = ApiErrorType.badRequest;
        break;
      case 401:
        statusMessage = 'Unauthorized';
        type = ApiErrorType.unauthorized;
        break;
      case 403:
        statusMessage = 'Forbidden';
        type = ApiErrorType.forbidden;
        break;
      case 404:
        statusMessage = 'Not Found';
        type = ApiErrorType.notFound;
        break;
      case 408:
        statusMessage = 'Request Timeout';
        type = ApiErrorType.timeout;
        break;
      case 429:
        statusMessage = 'Too Many Requests';
        type = ApiErrorType.rateLimit;
        break;
      case 500:
        statusMessage = 'Internal Server Error';
        type = ApiErrorType.server;
        break;
      case 503:
        statusMessage = 'Service Unavailable';
        type = ApiErrorType.serverUnavailable;
        break;
      default:
        statusMessage = 'Unexpected Error (${res.statusCode})';
        type = (res.statusCode != null && res.statusCode! >= 500)
            ? ApiErrorType.server
            : ApiErrorType.unknown;
    }

    // FINAL DECISION: Use server message if available, else usage status message
    return ApiError(
      message: serverMessage?.toString() ?? statusMessage,
      type: type,
      code: res.statusCode,
      response: errorModel,
    );
  }

  static Future<void> _authGuard(int? statusCode) async {
    if (statusCode == 401) {
      await TokenStorage.deleteToken();
    }
  }
}
