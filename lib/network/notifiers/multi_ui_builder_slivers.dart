import 'package:flutter/material.dart';
import '../api_services/state_response.dart';
import '../api_services/api_error.dart';

class MultiUiBuilderSlivers extends StatelessWidget {
  final List<StateResponse> states;
  final List<Widget> Function() onSuccess;
  final List<Widget> Function()? onLoading;
  final List<Widget> Function()? onIdle;
  final List<Widget> Function(ApiError error)? onFailure;
  final List<Widget> Function(String message)? onException;

  const MultiUiBuilderSlivers({
    super.key,
    required this.states,
    required this.onSuccess,
    this.onLoading,
    this.onIdle,
    this.onFailure,
    this.onException,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: _buildSlivers());
  }

  List<Widget> _buildSlivers() {
    if (states.isEmpty) {
      return onIdle?.call() ?? [];
    }

    // Check for failure/exception first as they have priority
    for (final s in states) {
      if (s.state == States.failure) {
        return onFailure?.call(
              ApiError(
                message: s.message,
                type: s.errorType ?? ApiErrorType.unknown,
                code: s.code,
              ),
            ) ??
            [];
      }
    }

    for (final s in states) {
      if (s.state == States.exception) {
        return onException?.call(s.message) ?? [];
      }
    }

    for (final s in states) {
      if (s.state == States.loading) {
        return onLoading?.call() ?? [];
      }
    }

    for (final s in states) {
      if (s.state == States.idle) {
        return onIdle?.call() ?? [];
      }
    }

    for (final s in states) {
      if (s.state == States.refreshing) {
        return onSuccess();
      }
    }

    if (states.every((s) => s.state == States.success)) {
      return onSuccess();
    }

    return onIdle?.call() ?? [];
  }
}
