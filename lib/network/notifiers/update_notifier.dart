import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_text.dart';
import 'package:toastification/toastification.dart';
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

  void showToast({
    required String message,
    String? submessage,
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      title: Txt(message, size: Dimen.s16, weight: Font.medium),
      description: (submessage != null && submessage.trim().isNotEmpty)
          ? Text(submessage)
          : null,
      type: type,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topCenter,
    );
  }

  String resolveMessage(String defaultMsg, States state) {
    return messageOverrides != null && messageOverrides.containsKey(state)
        ? messageOverrides[state]!
        : defaultMsg;
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

        String msg = response.message;
        // Priority: Use the nested message in data if the top-level message is default "Success"
        if (msg == "Success" || msg.isEmpty) {
          try {
            final dynamic data = response.data;
            if (data != null) {
              if (data is Map && data['message'] != null) {
                msg = data['message'].toString();
              } else if (data.message != null &&
                  data.message.toString().isNotEmpty) {
                msg = data.message.toString();
              }
            }
          } catch (_) {}
        }

        showToast(
          message: resolveMessage(msg, States.success),
          type: ToastificationType.success,
        );
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
        if (response.errorType != ApiErrorType.cancelled) {
          final subMsg = error.response?.errors.toString();
          showToast(
            message: resolveMessage(response.message, States.failure),
            submessage: (subMsg != null && subMsg.isNotEmpty)
                ? subMsg
                : response.data.toString(),
            type: ToastificationType.warning,
          );
        }
      }
      break;

    case States.exception:
      await onException?.call(response.message);
      if (!disableExceptionToast) {
        showToast(
          message: resolveMessage(response.message, States.exception),
          type: ToastificationType.error,
        );
      }
      break;
  }
}
