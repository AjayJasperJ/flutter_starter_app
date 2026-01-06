import 'api_error.dart';

class StateResponse<T> {
  final States state;
  final String message;
  final T? data;
  final ApiErrorType? errorType;
  final int? code;
  final bool isRefreshing;
  final bool isFromCache;

  const StateResponse({
    required this.state,
    required this.message,
    this.data,
    this.errorType,
    this.code,
    this.isRefreshing = false,
    this.isFromCache = false,
  });
  factory StateResponse.idle() => StateResponse(state: States.idle, message: 'Page idle');

  factory StateResponse.success(T data, {String? message, bool isFromCache = false}) =>
      StateResponse(
        state: States.success,
        message: message ?? "Success",
        data: data,
        isRefreshing: false,
        isFromCache: isFromCache,
      );

  factory StateResponse.refreshing(T data, {String? message, bool isFromCache = false}) =>
      StateResponse(
        state: States.refreshing,
        message: message ?? "Refreshing...",
        data: data,
        isRefreshing: true,
        isFromCache: isFromCache,
      );

  factory StateResponse.failure(ApiError error) {
    T? data;
    try {
      if (error.response is T) {
        data = error.response as T;
      }
    } catch (_) {}
    return StateResponse(
      state: States.failure,
      message: error.message,
      errorType: error.type,
      code: error.code,
      data: data,
    );
  }

  factory StateResponse.exception(String message, {T? data}) =>
      StateResponse(state: States.exception, message: message, data: data);

  factory StateResponse.loading({String? message}) =>
      StateResponse(state: States.loading, message: message ?? "Loading...");

  bool get isSuccess => state == States.success;
  bool get isFailure => state == States.failure;
  bool get isLoading => state == States.loading;
  bool get isIdle => state == States.idle;
  bool get isException => state == States.exception;
  bool get refreshing => state == States.refreshing;
}

enum States { idle, loading, success, failure, exception, refreshing }
