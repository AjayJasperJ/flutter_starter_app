import 'dart:async';
import 'package:flutter/widgets.dart';
import '../api_services/api_client.dart';

/// Mixin to easily listen for SWR (Stale-While-Revalidate) updates from [ApiClient].
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with SwrMixin {
///   @override
///   void initState() {
///     super.initState();
///     // Automatically refreshes when '/my-path' is updated in background
///     listenToSwr('/my-path', () {
///       _fetchData();
///     });
///   }
/// }
/// ```
mixin SwrMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<String>? _refreshSubscription;

  /// Starts listening to global specific refreshes.
  ///
  /// [onRefresh] will be called whenever [ApiClient] broadcasts that [path]
  /// has new data available (e.g. after a background revalidation).
  void listenToSwr(String path, VoidCallback onRefresh) {
    _refreshSubscription?.cancel();
    _refreshSubscription = ApiClient.refreshStream.listen((refreshedPath) {
      // Check if the refreshed path matches our target path
      // We check for exact match or if the refreshed path contains our path
      // (Simple containment check, can be made more robust if needed)
      if (refreshedPath.contains(path)) {
        if (mounted) {
          onRefresh();
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }
}
