import 'package:flutter/widgets.dart';
import '../../core/config/environment.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../dev_tools/features/environment_switcher/environment_controller.dart';
import '../../core/utils/notification_service.dart';
import '../api_services/api_client.dart';
import '../utils/logger_services.dart';

const String kBackgroundSyncTask = 'com.myapp.backgroundSync';
const String kPeriodicSyncReminderTask = 'com.myapp.periodicSyncReminder';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[BACKGROUND SYNC-v2] Isolate initialized. Task: $task');
    try {
      await Hive.initFlutter();
      if (!Hive.isBoxOpen('api_cache')) await Hive.openBox('api_cache');
      if (!Hive.isBoxOpen('offline_queue')) await Hive.openBox('offline_queue');
      await LoggerService.init();
      await NotificationService().init(isBackground: true);
      try {
        await Environment.load();
      } catch (e) {
        debugPrint(
          "Env load failed (expected in production if using build args): $e",
        );
      }

      if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
      final settingsBox = Hive.box('settings');
      final bool isAppInForeground = settingsBox.get(
        'isAppInForeground',
        defaultValue: false,
      );

      debugPrint(
        '[BACKGROUND SYNC] Task $task starting. isInForeground: $isAppInForeground',
      );

      if (task == kBackgroundSyncTask) {
        await LoggerService.log(
          level: LogLevel.info,
          category: 'background_sync',
          message:
              'Starting sync task: $task | isInForeground: $isAppInForeground',
        );

        final queueBox = Hive.box('offline_queue');
        final initialQueueSize = queueBox.length;

        await EnvironmentController().init();
        debugPrint(
          '[BACKGROUND SYNC] Environment initialized. Current apiUrl: ${Environment.apiUrl}',
        );
        final apiClient = ApiClient();
        await apiClient.syncOfflineData();

        // Notification logic: only if something was synced and app NOT in foreground
        if (initialQueueSize > 0 && queueBox.isEmpty && !isAppInForeground) {
          await NotificationService().showNotification(
            id: 100,
            title: 'Scola Sync Success',
            body: 'Offline data has been successfully synchronized.',
          );
        }

        await LoggerService.log(
          level: LogLevel.info,
          category: 'background_sync',
          message: 'Sync task completed successfully.',
        );
      } else if (task == kPeriodicSyncReminderTask) {
        // Only show reminder if device is OFFLINE and has items AND app NOT in foreground
        final results = await Connectivity().checkConnectivity();
        final isOnline = results.any((r) => r != ConnectivityResult.none);

        if (!isOnline && !isAppInForeground) {
          final queueBox = Hive.box('offline_queue');
          if (queueBox.isNotEmpty) {
            await LoggerService.log(
              level: LogLevel.info,
              category: 'background_sync',
              message:
                  'Periodic reminder triggered: ${queueBox.length} items pending offline.',
            );
            await NotificationService().showNotification(
              id: 101,
              title: 'Offline Sync Status',
              body:
                  'You are offline. ${queueBox.length} items will be synced when connection is restored.',
            );
          }
        }
      }

      return true;
    } catch (e, stack) {
      debugPrint('[BACKGROUND SYNC] Error in task $task: $e');
      await LoggerService.log(
        level: LogLevel.error,
        category: 'background_sync',
        message: 'Critical Failure: $e',
        details: {'stack': stack.toString()},
      );
      return false;
    }
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;

  BackgroundSyncService._internal();

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
    await Workmanager().registerPeriodicTask(
      'periodic_sync_reminder_unique',
      kPeriodicSyncReminderTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        // Removing networkType constraint to ensure it runs even offline
        requiresBatteryNotLow: false,
      ),
    );
    debugPrint(
      '[BACKGROUND SYNC] Initialized (15min periodicity - replace policy)',
    );
  }

  void scheduleSyncTask() {
    Workmanager().registerOneOffTask(
      'bg_sync_unique_work',
      kBackgroundSyncTask,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
    debugPrint(
      '[BACKGROUND SYNC] Scheduled one-off sync task (Replace policy)',
    );
  }
}
