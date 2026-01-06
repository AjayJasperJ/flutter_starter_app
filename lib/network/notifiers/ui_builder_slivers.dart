import 'package:flutter/material.dart';
import '../api_services/api_error.dart';
import '../api_services/state_response.dart';
import '../utils/network_utils.dart';

class UiBuilderSlivers<T> extends StatelessWidget {
  final StateResponse<dynamic>? response;
  final List<Widget> Function(T? data) onSuccess;
  final List<Widget> Function()? onLoading;
  final List<Widget> Function()? onIdle;
  final List<Widget> Function(ApiError error)? onFailure;
  final List<Widget> Function(String message)? onException;
  final List<Widget> Function(T? data)? onRefreshing;
  final VoidCallback? onRetry;
  final void Function(StateResponse<dynamic>? response)? listener;
  const UiBuilderSlivers({
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
    return SliverMainAxisGroup(slivers: _buildSlivers());
  }

  List<Widget> _buildSlivers() {
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
        return onIdle?.call() ?? [];
      case States.loading:
        return onLoading?.call() ?? [];
      case States.success:
        return onSuccess(castData(response?.data));
      case States.refreshing:
        final content =
            onRefreshing?.call(castData(response?.data)) ?? onSuccess(castData(response?.data));

        if (onRefreshing == null) {
          return [...content];
        }
        return content;
      case States.failure:
        final error = ApiError(
          message: response?.message ?? "Unknown error",
          type: response?.errorType ?? ApiErrorType.unknown,
          code: response?.code,
        );
        final failureContent = onFailure?.call(error) ?? [];
        if (onRetry != null && failureContent.isNotEmpty) {}
        return failureContent;
      case States.exception:
        return onException?.call(response?.message ?? "Unknown exception") ?? [];
      case null:
        return onIdle?.call() ?? [];
    }
  }
}
