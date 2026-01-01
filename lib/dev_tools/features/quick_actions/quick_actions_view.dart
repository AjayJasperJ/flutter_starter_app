import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/token_storage.dart';
import '../../../network/api_services/api_client.dart';
import '../../../routes/route_services.dart';
import '../../../core/utils/notification_service.dart';
import '../../dev_tools_controller.dart';
import '../logs/logs_controller.dart';
import '../network_inspector/network_controller.dart';
import '../network_throttling/network_throttling_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

class QuickActionsView extends StatelessWidget {
  const QuickActionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.all(Dimen.w16),
        children: [
          Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: Dimen.s11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: Dimen.h16),
          _buildThrottlingSection(),
          SizedBox(height: Dimen.h24),
          Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: Dimen.s11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: Dimen.h16),
          _ActionTile(
            icon: Icons.assignment_rounded,
            title: 'Copy Diagnostic Report',
            subtitle: 'Generate report of logs & network',
            color: Colors.blueAccent,
            onTap: () => _copyDiagnosticReport(context),
          ),
          _ActionTile(
            icon: Icons.logout,
            title: 'Force Logout',
            subtitle: 'Clear auth tokens and logout',
            color: Colors.redAccent,
            onTap: () => _forceLogout(context),
          ),
          _ActionTile(
            icon: Icons.cleaning_services,
            title: 'Clear All Data',
            subtitle: 'Reset cache, storage & re-sync',
            color: Colors.orangeAccent,
            onTap: () => _clearAllData(context),
          ),
          _ActionTile(
            icon: Icons.refresh,
            title: 'Restart App',
            subtitle: 'Force restart application',
            onTap: () => _restartApp(context),
          ),
          SizedBox(height: Dimen.h24),
          Text(
            'NOTIFICATION TESTING',
            style: TextStyle(
              color: Colors.white38,
              fontSize: Dimen.s11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: Dimen.h16),
          _ActionTile(
            icon: Icons.notifications_active,
            title: 'Test Notification Service',
            subtitle: 'Show immediate system notification',
            color: Colors.purpleAccent,
            onTap: () => _testNotificationService(context),
          ),
          _ActionTile(
            icon: Icons.sync_problem,
            title: 'Trigger Background Sync Logic',
            subtitle: 'Process queue and show success alert',
            color: Colors.tealAccent,
            onTap: () => _testSyncLogic(context),
          ),
          _ActionTile(
            icon: Icons.alarm,
            title: 'Trigger Periodic Reminder',
            subtitle: 'Check queue and show pending alert',
            color: Colors.amberAccent,
            onTap: () => _testPeriodicReminder(context),
          ),
        ],
      ),
    );
  }

  Widget _buildThrottlingSection() {
    final controller = NetworkThrottlingController();
    return Container(
      padding: EdgeInsets.all(Dimen.w12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.blueAccent, size: Dimen.h18),
              SizedBox(width: Dimen.w8),
              Text(
                'Network Speed Simulation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Dimen.s13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimen.h12),
          ValueListenableBuilder<ThrottlingProfile>(
            valueListenable: controller.activeProfile,
            builder: (context, activeProfile, _) {
              return Wrap(
                spacing: Dimen.w8,
                runSpacing: Dimen.h8,
                children: ThrottlingProfile.values.map((profile) {
                  final isSelected = activeProfile == profile;
                  return GestureDetector(
                    onTap: () => controller.setProfile(profile),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimen.w12,
                        vertical: Dimen.h8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(Dimen.r8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        profile.shortLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white38,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          letterSpacing: 1.1,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          SizedBox(height: Dimen.h8),
          Text(
            'Injects artificial latency to simulate real-world conditions.',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _copyDiagnosticReport(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('# DevTools Diagnostic Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln(
      'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
    buffer.writeln('\n---');

    // Logs
    buffer.writeln(
      '\n## APPLICATION LOGS (${LogsController().logs.value.length})',
    );
    for (var log in LogsController().logs.value.reversed.take(50)) {
      buffer.writeln('[${log['time']}] ${log['level']}: ${log['message']}');
    }

    // Network
    buffer.writeln(
      '\n## NETWORK TRAFFIC (${NetworkController().apiLogs.value.length})',
    );
    for (var api in NetworkController().apiLogs.value.reversed.take(20)) {
      buffer.writeln(
        '[${api['time']}] ${api['method']} ${api['status']} ${api['path']}',
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Diagnostic report copied to clipboard'),
          backgroundColor: Colors.greenAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimen.r8),
          ),
        ),
      );
    }
  }

  void _forceLogout(BuildContext context) async {
    await TokenStorage.deleteToken();
    TokenStorage.updatelogged(false);
    debugPrint('[DevTools] Force logout executed');

    if (!context.mounted) return;
    Navigator.of(context).pop();
    RouteServices.removeUntil('/login', (route) => false);
  }

  void _clearAllData(BuildContext context) async {
    final controller = AppDevToolsController();
    await controller.resetCache();
    debugPrint('[DevTools] All data cleared');

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data cleared')));
  }

  void _restartApp(BuildContext context) {
    debugPrint('[DevTools] App restart requested');
    Navigator.of(context).pop();
    RouteServices.removeUntil('/login', (route) => false);
  }

  void _testNotificationService(BuildContext context) async {
    await NotificationService().init(isBackground: false);
    await NotificationService().showNotification(
      id: 999,
      title: 'DevTools Test',
      body: 'This is a test notification from DevTools Quick Actions.',
    );
  }

  void _testSyncLogic(BuildContext context) async {
    final apiClient = ApiClient();
    await apiClient.syncOfflineData();
    final queueBox = Hive.box('offline_queue');
    if (queueBox.isEmpty) {
      await NotificationService().init(isBackground: false);
      await NotificationService().showNotification(
        id: 100,
        title: 'Scola Sync Success (Test)',
        body: 'Offline data has been successfully synchronized.',
      );
    }
  }

  void _testPeriodicReminder(BuildContext context) async {
    final queueBox = Hive.box('offline_queue');
    if (queueBox.isNotEmpty) {
      await NotificationService().init(isBackground: false);
      await NotificationService().showNotification(
        id: 101,
        title: 'Pending Sync Items (Test)',
        body: 'You have ${queueBox.length} items waiting to be synced.',
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queue is empty. No reminder triggered.'),
          ),
        );
      }
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = Colors.blueAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimen.h12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(Dimen.w8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Dimen.r8),
          ),
          child: Icon(icon, color: color, size: Dimen.h20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: Dimen.s14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white24,
          size: Dimen.h16,
        ),
      ),
    );
  }
}
