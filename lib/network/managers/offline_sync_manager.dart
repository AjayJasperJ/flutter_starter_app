import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api_services/api_client.dart';
import '../services/background_sync_service.dart';
import '../utils/connectivity_service.dart';

class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;

  late final ApiClient _apiClient;
  StreamSubscription? _connectivitySubscription;

  OfflineSyncManager._internal() {
    _apiClient = ApiClient();
  }

  void init() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = ConnectivityService().connectionChange.listen((
      isConnected,
    ) {
      if (isConnected) {
        debugPrint('[SYNC MANAGER] Connection restored. Triggering sync...');
        _apiClient.syncOfflineData();
      }
      if (isConnected) {
        debugPrint('[SYNC MANAGER] Connection restored. Triggering sync...');
        _apiClient.syncOfflineData();
      }
    });

    // Also schedule the background worker to ensure redundancy
    // This makes sure if the app dies, the OS knows we want to run this task on next connection
    BackgroundSyncService().scheduleSyncTask();

    if (ConnectivityService().hasConnection) {
      _apiClient.syncOfflineData();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _apiClient.dispose();
  }
}
