import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_starter_app/dev_tools/dev_tools_constants.dart';
import 'package:flutter_starter_app/dev_tools/dev_tools_controller.dart';
import 'package:flutter_starter_app/dev_tools/features/auth_tools/devtools_auth_controller.dart';
import 'package:flutter_starter_app/dev_tools/features/environment_switcher/environment_controller.dart';
import 'package:flutter_starter_app/dev_tools/features/feature_flags/feature_flag_controller.dart';
import 'package:flutter_starter_app/dev_tools/features/mocking/mock_controller.dart';
import 'package:flutter_starter_app/dev_tools/features/network_throttling/network_throttling_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../app.dart';
import '../../../core/config/environment.dart';
import '../../../core/utils/deeplink_services.dart';
import '../../../data/token_storage.dart';
import '../../../network/services/background_sync_service.dart';
import '../../../network/utils/connectivity_service.dart';
import '../../../network/utils/logger_services.dart';
import '../../../network/managers/offline_sync_manager.dart';

Future<void> bootstrap({
  bool enableDevTools = DevToolsConstants.kIncludeDevTools,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await BackgroundSyncService().init();
  } catch (e) {
    debugPrint('Failed to init background sync: $e');
  }
  await Hive.initFlutter();
  await Hive.openBox('api_cache');
  await Hive.openBox('offline_queue');
  if (DevToolsConstants.kIncludeDevTools) {
    AppDevToolsController().init(enableDevTools: enableDevTools);
  }
  final deepLinkService = DeepLinkService();
  final lifecycleHandler = AppLifecycleHandler(deepLinkService);
  TokenStorage.updatelogged(await TokenStorage.getToken() != null);
  WidgetsBinding.instance.addObserver(lifecycleHandler);
  try {
    await Environment.load();
    if (enableDevTools) {
      await EnvironmentController().init();
    }
  } catch (e) {
    debugPrint(
      "Env load failed (expected in production if using build args): $e",
    );
  }
  await LoggerService.init();
  LoggerService.initGlobalErrorHandling();
  await ConnectivityService().init();
  OfflineSyncManager().init();
  if (DevToolsConstants.kIncludeDevTools) {
    await DevToolsAuthController().init();
    await FeatureFlagController().init();
    await MockController().init();
    await NetworkThrottlingController().init();
  }
  debugPrint("[Bootstrap] Initialization complete.");
}
