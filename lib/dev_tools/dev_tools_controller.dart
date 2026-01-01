import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppDevToolsController {
  AppDevToolsController._internal();
  static final AppDevToolsController _instance =
      AppDevToolsController._internal();
  factory AppDevToolsController() => _instance;

  // Configuration
  bool enabled = false;
  bool _isRunning = false;
  Timer? _metricsTimer;

  // Global monitoring states
  final ValueNotifier<bool> isMonitoringActive = ValueNotifier<bool>(true);
  final ValueNotifier<int> logCount = ValueNotifier<int>(0);
  final ValueNotifier<String> currentEnv = ValueNotifier<String>('Development');

  // App Info
  final ValueNotifier<String> appName = ValueNotifier<String>('Loading...');
  final ValueNotifier<String> version = ValueNotifier<String>('0.0.0');
  final ValueNotifier<String> buildNumber = ValueNotifier<String>('0');
  final ValueNotifier<String> packageName = ValueNotifier<String>(
    'com.example.app',
  );

  // Device Info
  final ValueNotifier<String> deviceModel = ValueNotifier<String>(
    'Determining...',
  );
  final ValueNotifier<String> deviceBrand = ValueNotifier<String>(
    'Determining...',
  );

  // Connectivity
  final ValueNotifier<String> localIP = ValueNotifier<String>('Searching...');
  final ValueNotifier<String> connectionType = ValueNotifier<String>(
    'Checking...',
  );

  // Metrics
  final ValueNotifier<double> fps = ValueNotifier<double>(60.0);
  final ValueNotifier<double> memoryUsage = ValueNotifier<double>(0.0); // In MB
  final ValueNotifier<double> cacheSize = ValueNotifier<double>(0.0); // In MB

  // FPS tracking - smoothed
  final List<double> _fpsHistory = [];
  static const int _fpsSampleCount = 10;
  Duration? _lastFrameTime;

  void init({required bool enableDevTools}) {
    enabled = enableDevTools;
    if (enabled && !_isRunning) {
      _isRunning = true;
      _calculateCacheSize();
      _startMetricsTicking();
      _initAppInfo();
      _initDeviceInfo();
      _initConnectivityTracking();
    }
  }

  Future<void> _initDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel.value = androidInfo.model;
        deviceBrand.value = androidInfo.brand.toUpperCase();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel.value = iosInfo.utsname.machine;
        deviceBrand.value = 'APPLE';
      }
    } catch (e) {
      debugPrint("[DevTools] Error fetching device info: $e");
    }
  }

  void _initConnectivityTracking() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty) {
        _updateConnectivityState(results.first);
      }
    });

    // Initial fetch
    Connectivity().checkConnectivity().then((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectivityState(results.first);
      }
    });

    _updateIPAddress();
  }

  Future<void> _updateConnectivityState(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType.value = 'WIFI';
        break;
      case ConnectivityResult.mobile:
        connectionType.value = 'CELLULAR';
        break;
      case ConnectivityResult.none:
        connectionType.value = 'NONE';
        break;
      default:
        connectionType.value = result.name.toUpperCase();
    }
    _updateIPAddress();
  }

  Future<void> _updateIPAddress() async {
    try {
      final String? ip = await NetworkInfo().getWifiIP();
      localIP.value = ip ?? 'Not available';
    } catch (e) {
      localIP.value = 'Error';
      debugPrint("[DevTools] Error fetching IP: $e");
    }
  }

  Future<void> _initAppInfo() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      appName.value = info.appName;
      version.value = info.version;
      buildNumber.value = info.buildNumber;
      packageName.value = info.packageName;
      debugPrint(
        "[DevTools] App Info initialized: ${info.appName} v${info.version}",
      );
    } catch (e) {
      debugPrint("[DevTools] Error initializing app info: $e");
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;
      if (await appDir.exists()) {
        await for (final entity in appDir.list(recursive: true)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (_) {}
          }
        }
      }

      // Add Hive boxes sizes
      for (final boxName in ['api_cache', 'offline_queue']) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          // Rough estimate based on number of entries
          totalSize += box.length * 500; // ~500 bytes per entry average
        }
      }

      cacheSize.value = totalSize / (1024 * 1024);
    } catch (e) {
      debugPrint("[DevTools] Error calculating cache size: $e");
    }
  }

  Future<void> resetCache() async {
    try {
      // 1. Clear Hive boxes (not delete from disk to avoid re-init issues)
      if (Hive.isBoxOpen('api_cache')) {
        await Hive.box('api_cache').clear();
      }
      if (Hive.isBoxOpen('offline_queue')) {
        await Hive.box('offline_queue').clear();
      }

      // 2. Clear temporary cache directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }

      // 3. Recalculate size
      await _calculateCacheSize();
      debugPrint('[DevTools] Cache cleared successfully');
    } catch (e) {
      debugPrint('[DevTools] Error clearing cache: $e');
    }
  }

  void setEnv(String env) {
    currentEnv.value = env;
  }

  void _startMetricsTicking() {
    // FPS Tracking using persistent frame callback
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

    // Periodic updates for memory and cache
    _metricsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!enabled || !isMonitoringActive.value) return;
      _updateMemoryUsage();
    });

    // Less frequent cache size updates (reduced from 10s to 60s for production)
    Timer.periodic(const Duration(seconds: 60), (_) {
      if (!enabled) return;
      _calculateCacheSize();
    });
  }

  void _onFrame(Duration timestamp) {
    if (!enabled || !isMonitoringActive.value) return;

    if (_lastFrameTime != null) {
      final durationMicro =
          timestamp.inMicroseconds - _lastFrameTime!.inMicroseconds;
      if (durationMicro > 0) {
        final instantFps = 1000000.0 / durationMicro;

        // Add to history and maintain window size
        _fpsHistory.add(instantFps);
        if (_fpsHistory.length > _fpsSampleCount) {
          _fpsHistory.removeAt(0);
        }

        // Calculate smoothed average
        final avgFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
        fps.value = avgFps.clamp(0.0, 120.0); // Clamp to reasonable range
      }
    }
    _lastFrameTime = timestamp;
  }

  void _updateMemoryUsage() {
    try {
      // Get current RSS memory usage
      final rssBytes = ProcessInfo.currentRss;
      memoryUsage.value = rssBytes / (1024 * 1024);
    } catch (e) {
      debugPrint("[DevTools] Error reading memory: $e");
    }
  }

  void toggleMonitoring() {
    isMonitoringActive.value = !isMonitoringActive.value;
  }

  void dispose() {
    _metricsTimer?.cancel();
    isMonitoringActive.dispose();
    logCount.dispose();
    currentEnv.dispose();
    fps.dispose();
    memoryUsage.dispose();
    cacheSize.dispose();
  }
}
