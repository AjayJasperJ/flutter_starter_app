import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_services/state_response.dart';
import '../utils/connectivity_service.dart';

mixin AutoReconnectMixin on ChangeNotifier {
  StreamSubscription<bool>? _connectivitySubscription;
  void onReconnect();
  bool get shouldRetry => false;

  void initAutoReconnect() {
    _connectivitySubscription = ConnectivityService().connectionChange.listen((hasConnection) {
      if (hasConnection && shouldRetry) {
        onReconnect();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
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
