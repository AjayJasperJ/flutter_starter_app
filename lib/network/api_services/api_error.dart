import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/token_storage.dart';

import '../../models/api_response_model.dart';

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
    ApiResponseModel? errorModel;
    final data = res.data;
    try {
      if (data != null && data.toString().trim().isNotEmpty) {
        final Map<String, dynamic> decodedData = data is String
            ? jsonDecode(data)
            : data as Map<String, dynamic>;
        errorModel = ApiResponseModel.fromJson(decodedData);
      }
    } catch (e) {
      if (kDebugMode) print("[ErrorHandler] Error parsing error message: $e");
    }

    _authGuard(res.statusCode);

    String defaultMsg;
    ApiErrorType type;

    switch (res.statusCode) {
      case 400:
        defaultMsg =
            'Bad Request – The server could not understand your request.';
        type = ApiErrorType.badRequest;
        break;
      case 401:
        defaultMsg = 'Unauthorized – Please log in again.';
        type = ApiErrorType.unauthorized;
        break;
      case 403:
        defaultMsg = 'Forbidden – You do not have permission for this action.';
        type = ApiErrorType.forbidden;
        break;
      case 404:
        defaultMsg = 'Not Found – The requested resource was not found.';
        type = ApiErrorType.notFound;
        break;
      case 408:
        defaultMsg = 'Request Timeout – The server took too long to respond.';
        type = ApiErrorType.timeout;
        break;
      case 429:
        defaultMsg = 'Too Many Requests – You’re sending requests too quickly.';
        type = ApiErrorType.rateLimit;
        break;
      case 500:
        defaultMsg =
            'Internal Server Error – Something went wrong on the server.';
        type = ApiErrorType.server;
        break;
      case 503:
        defaultMsg = 'Service Unavailable – The server is temporarily offline.';
        type = ApiErrorType.serverUnavailable;
        break;
      default:
        defaultMsg = 'Unexpected HTTP error (${res.statusCode}).';
        type = ApiErrorType.unknown;
    }
    final message = errorModel?.message ?? defaultMsg;
    return ApiError(
      message: message,
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

  static String exceptionMessage = "Exception Found : Contact Developer";
}
