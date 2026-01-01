import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api_services/api_error.dart';
import '../api_services/state_response.dart';

Future<void> updateNotifier<T>(
  BuildContext context, {
  required StateResponse<dynamic> response,
  Future<void> Function(States state)? onInit,
  Future<void> Function(T? data)? onSuccess,
  Future<void> Function(ApiError error)? onFailure,
  Future<void> Function(String message)? onException,
  bool disableSuccessToast = false,
  bool disableFailureToast = false,
  bool disableExceptionToast = false,
  bool disableCancelledToast = true,
  bool enableHaptics = true,
  Map<States, String>? messageOverrides,
}) async {
  if (onInit != null) {
    await onInit(response.state);
  }

  T? castData(dynamic data) {
    if (data == null) return null;
    if (data is T) return data;
    try {
      return data as T;
    } catch (_) {
      return null;
    }
  }

  switch (response.state) {
    case States.idle:
      break;
    case States.loading:
      break;
    case States.refreshing:
      break;
    case States.success:
      await onSuccess?.call(castData(response.data));
      if (!disableSuccessToast) {
        if (enableHaptics) HapticFeedback.lightImpact();
      }
      break;

    case States.failure:
      final error = ApiError(
        message: response.message,
        type: response.errorType ?? ApiErrorType.unknown,
        code: response.code,
        response: response.data,
      );
      await onFailure?.call(error);
      if (!disableFailureToast) {
        if (enableHaptics) HapticFeedback.mediumImpact();
      }
      break;

    case States.exception:
      await onException?.call(response.message);
      break;
  }
}
