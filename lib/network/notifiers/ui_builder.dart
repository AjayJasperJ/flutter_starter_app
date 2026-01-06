import 'package:flutter/material.dart';
import '../api_services/api_error.dart';
import '../api_services/state_response.dart';
import '../utils/network_utils.dart';

/// A "Lite" version of [UiBuilder] for regular (non-sliver) UI builds.
/// Use this for components like Cards, Profile Headers, or single-child widgets
/// that are NOT inside a [CustomScrollView].
class UiBuilder<T> extends StatelessWidget {
  final StateResponse<dynamic>? response;
  final Widget Function(T? data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function()? onIdle;
  final Widget Function(ApiError error)? onFailure;
  final Widget Function(String message)? onException;
  final Widget Function(T? data)? onRefreshing;
  final VoidCallback? onRetry;
  final void Function(StateResponse<dynamic>? response)? listener;

  const UiBuilder({
    super.key,
    this.response,
    required this.onSuccess,
    this.onLoading,
    this.onIdle,
    this.onFailure,
    this.onException,
    this.onRefreshing,
    this.onRetry,
    this.listener,
  });

  @override
  Widget build(BuildContext context) {
    if (listener != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        listener!(response);
      });
    }

    if (response?.isFromCache == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NetworkUtils.notifyCacheUse(context);
      });
    }

    T? castData(dynamic data) {
      if (data == null) {
        return null;
      }
      if (data is T) {
        return data;
      }
      try {
        return data as T;
      } catch (_) {
        return null;
      }
    }

    switch (response?.state) {
      case States.idle:
        return onIdle?.call() ?? const SizedBox.shrink();
      case States.loading:
        return onLoading?.call() ?? const Center(child: CircularProgressIndicator());
      case States.success:
        return onSuccess(castData(response?.data));
      case States.refreshing:
        final content =
            onRefreshing?.call(castData(response?.data)) ?? onSuccess(castData(response?.data));

        return content;
      case States.failure:
        final error = ApiError(
          message: response?.message ?? "Unknown error",
          type: response?.errorType ?? ApiErrorType.unknown,
          code: response?.code,
          response: response?.data,
        );
        return onFailure?.call(error) ??
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.message),
                  if (onRetry != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
                  ],
                ],
              ),
            );
      case States.exception:
        return onException?.call(response?.message ?? "Unknown exception") ??
            const SizedBox.shrink();
      case null:
        return onIdle?.call() ?? const SizedBox.shrink();
    }
  }
}
