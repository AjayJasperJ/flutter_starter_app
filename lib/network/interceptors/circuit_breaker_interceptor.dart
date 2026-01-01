import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CircuitBreakerInterceptor extends Interceptor {
  int _failureCount = 0;
  static const int _threshold = 5;
  static const Duration _resetInterval = Duration(seconds: 30);
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isOpen) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > _resetInterval) {
        // Half-open state: Allow one request to verify if service is back
        debugPrint('[CircuitBreaker] Half-open: Allowing trial request');
        _isOpen = false;
        _failureCount = 0; // Reset count for trial
      } else {
        debugPrint(
          '[CircuitBreaker] Circuit is OPEN. Blocking request to ${options.path}',
        );
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'CircuitBreaker: Service is temporarily unavailable.',
          ),
        );
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // A successful response resets the circuit
    if (_failureCount > 0) {
      _failureCount = 0;
      _isOpen = false;
      debugPrint('[CircuitBreaker] Request successful. Circuit closed.');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isServerFailure(err)) {
      _failureCount++;
      _lastFailureTime = DateTime.now();
      debugPrint(
        '[CircuitBreaker] Failure detected. Count: $_failureCount/$_threshold',
      );

      if (_failureCount >= _threshold) {
        _isOpen = true;
        debugPrint(
          '[CircuitBreaker] Threshold reached. Circuit OPEN for ${_resetInterval.inSeconds}s',
        );
      }
    }
    super.onError(err, handler);
  }

  bool _isServerFailure(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response != null &&
            err.response!.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}
