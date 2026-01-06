import 'dart:async';
import 'package:flutter/material.dart';

/// A mixin to throttle scroll notifications.
/// Use this when you have heavy logic (like pagination checks) attached to a ScrollController.
mixin ThrottledScrollMixin<T extends StatefulWidget> on State<T> {
  Timer? _scrollDebounce;
  final ScrollController scrollController = ScrollController();

  /// Override this to handle throttled scroll events
  void onScroll();

  /// The throttling duration. Default is 200ms.
  Duration get scrollThrottleDuration => const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
  }

  void _onScrollListener() {
    if (_scrollDebounce?.isActive ?? false) return;

    _scrollDebounce = Timer(scrollThrottleDuration, () {
      if (mounted) {
        onScroll();
      }
    });
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    scrollController.removeListener(_onScrollListener);
    scrollController.dispose();
    super.dispose();
  }
}
