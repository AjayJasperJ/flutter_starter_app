import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../../widgets/jump_to_bottom_fab.dart';
import '../auth_tools/devtools_auth_controller.dart';
import 'logs_controller.dart';

class LogsView extends StatefulWidget {
  const LogsView({super.key});

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final controller = LogsController();
  final authController = DevToolsAuthController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ensure controller is initialized
    controller.init();

    // Setup auto-scroll listener
    controller.logs.addListener(_autoScrollListener);
  }

  void _autoScrollListener() {
    if (controller.autoScroll.value && scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double check hasClients because the widget might be disposed
        // or the controller might be detached by the time this runs.
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    controller.logs.removeListener(_autoScrollListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: JumpToBottomFAB(scrollController: scrollController),
      body: Column(
        children: [
          _buildToolbar(controller, authController),
          Expanded(
            child: _buildLogList(controller, authController, scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    LogsController controller,
    DevToolsAuthController authController,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimen.w16, vertical: Dimen.h8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'System Logs',
            style: TextStyle(
              color: Colors.white54,
              fontSize: Dimen.s12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: controller.autoScroll,
                builder: (context, autoScroll, _) {
                  return IconButton(
                    icon: Icon(
                      autoScroll
                          ? Icons.arrow_downward
                          : Icons.arrow_downward_outlined,
                      color: autoScroll ? Colors.greenAccent : Colors.white38,
                      size: Dimen.h20,
                    ),
                    onPressed: controller.toggleAutoScroll,
                  );
                },
              ),
              if (authController.isDeveloper)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: Dimen.h20,
                  ),
                  onPressed: controller.clearLogs,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(
    LogsController controller,
    DevToolsAuthController authController,
    ScrollController scrollController,
  ) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: controller.logs,
      builder: (context, logs, _) {
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No logs available',
              style: TextStyle(color: Colors.white38, fontSize: Dimen.s14),
            ),
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.all(Dimen.w8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _LogTile(
              log: log,
              onTap: authController.isDeveloper
                  ? () => _showLogDetails(context, log, controller)
                  : null, // Read-only for regular users
            );
          },
        );
      },
    );
  }

  void _showLogDetails(
    BuildContext context,
    Map<String, dynamic> log,
    LogsController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: authController.isDeveloper
          ? const Color(0xFF0D1117)
          : const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimen.r16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _LogDetailsSheet(
          log: log,
          scrollController: scrollController,
          onDelete: () {
            controller.deleteLog(log);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback? onTap;

  const _LogTile({required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final level = log['level'] as String? ?? 'info';
    final isError =
        level == 'error' ||
        (log['message'] ?? '').toString().contains('success: false');
    final timestamp =
        (log['timestamp'] as String?)?.split('T').last.substring(0, 8) ??
        '00:00:00';
    final message = log['message'] ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Dimen.h8, horizontal: Dimen.w4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Dimen.w4,
              height: Dimen.h32,
              color: isError ? Colors.redAccent : Colors.greenAccent,
            ),
            SizedBox(width: Dimen.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '[$timestamp]',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: Dimen.s10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(width: Dimen.w8),
                      Text(
                        level.toUpperCase(),
                        style: TextStyle(
                          color: isError ? Colors.redAccent : Colors.white70,
                          fontSize: Dimen.s10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimen.h4),
                  Text(
                    message.toString(),
                    style: TextStyle(color: Colors.white, fontSize: Dimen.s13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: Dimen.h16, color: Colors.white10),
          ],
        ),
      ),
    );
  }
}

class _LogDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> log;
  final ScrollController scrollController;
  final VoidCallback onDelete;

  const _LogDetailsSheet({
    required this.log,
    required this.scrollController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimen.w16),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOG DETAILS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: Dimen.s12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: Dimen.h20,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimen.h16),
          _buildInfoRow('Timestamp', log['timestamp']),
          _buildInfoRow('Level', log['level']),
          _buildInfoRow('Message', log['message']),
          Divider(height: Dimen.h32, color: Colors.white10),
          _buildSection('Details', log['details']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimen.h8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
          ),
          SizedBox(height: Dimen.h2),
          SelectableText(
            value ?? 'N/A',
            style: TextStyle(color: Colors.white, fontSize: Dimen.s13),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, dynamic data) {
    if (data == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
        ),
        SizedBox(height: Dimen.h8),
        Container(
          padding: EdgeInsets.all(Dimen.w8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(Dimen.r8),
          ),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(data),
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: Dimen.s12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
