import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../network/utils/logger_services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init({bool isBackground = false}) async {
    try {
      final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
      final bool isActuallyForeground = state == AppLifecycleState.resumed;

      debugPrint(
        '[NOTIFICATION] init: isBackgroundParam=$isBackground, lifecycleState=$state, isActuallyForeground=$isActuallyForeground',
      );

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      // Wrap initialization in try-catch to prevent crashes in background isolates
      try {
        await _notificationsPlugin.initialize(initializationSettings);
      } catch (initError) {
        debugPrint('[NOTIFICATION] Native Initialize Error: $initError');
        if (isBackground) return; // Silent return if in background
        rethrow;
      }

      // Request permissions ONLY if we're explicitly in the foreground.
      // Background isolates (Workmanager) don't have an Activity context.
      if (!isBackground && isActuallyForeground) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          final bool? granted = await androidImplementation
              .requestNotificationsPermission();
          debugPrint(
            '[NOTIFICATION] Service initialized. Permission granted: $granted',
          );
        }
      } else {
        debugPrint(
          '[NOTIFICATION] Skipping permission request: isBackground=$isBackground, isActuallyForeground=$isActuallyForeground',
        );
      }

      await LoggerService.log(
        level: LogLevel.info,
        category: 'notifications',
        message:
            'Notification service initialized. IsBackground: $isBackground, State: $state',
      );
    } catch (e) {
      debugPrint('[NOTIFICATION] Outer Initialization Error: $e');
      await LoggerService.log(
        level: LogLevel.error,
        category: 'notifications',
        message: 'Outer Initialization Error: $e',
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      debugPrint(
        '[NOTIFICATION] Attempting to show notification: $id | $title',
      );
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'background_sync_channel',
            'Background Sync Notifications',
            channelDescription:
                'Notifications for background data synchronization progress',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
      );
      debugPrint('[NOTIFICATION] Notification $id sent successfully');
      await LoggerService.log(
        level: LogLevel.info,
        category: 'notifications',
        message: 'Notification sent: $id | $title',
      );
    } catch (e) {
      debugPrint('[NOTIFICATION] Show Error: $e');
      await LoggerService.log(
        level: LogLevel.error,
        category: 'notifications',
        message: 'Show Error: $e',
        details: {'id': id, 'title': title, 'error': e.toString()},
      );
    }
  }
}
