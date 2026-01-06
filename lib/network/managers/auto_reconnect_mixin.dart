import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_services/state_response.dart';
import '../api_services/api_client.dart'; // [NEW]
import '../utils/connectivity_service.dart';

mixin AutoReconnectMixin on ChangeNotifier {
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<String>? _refreshSubscription; // [NEW]
  void onReconnect();
  // [NEW] Callback for RAM auto-recovery updates
  void onAutoRefresh(String path) {}
  bool get shouldRetry => false;

  void initAutoReconnect() {
    _connectivitySubscription = ConnectivityService().connectionChange.listen((hasConnection) {
      if (hasConnection && shouldRetry) {
        onReconnect();
      }
    });

    // [NEW] Listen for successful network fetches
    _refreshSubscription = ApiClient.refreshStream.listen((path) {
      if (shouldRetry) {
        onAutoRefresh(path);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _refreshSubscription?.cancel(); // [NEW]
    super.dispose();
  }

  bool regularRetry(StateResponse? state, CancelToken? cancelToken) {
    if (state == null) {
      return false;
    }
    final bool needsRefresh = state.isFailure || state.isException;
    if (cancelToken == null) {
      return needsRefresh;
    }
    return needsRefresh && !cancelToken.isCancelled;
  }

  void cancelTokenNow(CancelToken? cancelToken, String? message) {
    if (cancelToken?.isCancelled == false && cancelToken != null) {
      cancelToken.cancel(message ?? "Request cancelled");
    }
  }
}
