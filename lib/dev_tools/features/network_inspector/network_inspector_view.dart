import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';
import '../../widgets/jump_to_bottom_fab.dart';
import '../auth_tools/devtools_auth_controller.dart';
import 'network_controller.dart';

class NetworkInspectorView extends StatelessWidget {
  const NetworkInspectorView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NetworkController();
    final authController = DevToolsAuthController();
    final scrollController = ScrollController();

    // Ensure controller is initialized
    controller.init();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: JumpToBottomFAB(scrollController: scrollController),
      body: Column(
        children: [
          _buildToolbar(context, controller, authController),
          Expanded(
            child: _buildNetworkList(
              controller,
              authController,
              scrollController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    NetworkController controller,
    DevToolsAuthController authController,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimen.w16, vertical: Dimen.h8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'API Traffic',
            style: TextStyle(
              color: Colors.white54,
              fontSize: Dimen.s12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (authController.isDeveloper)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: Dimen.h20,
              ),
              onPressed: controller.clear,
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkList(
    NetworkController controller,
    DevToolsAuthController authController,
    ScrollController scrollController,
  ) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: controller.apiLogs,
      builder: (context, logs, _) {
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No API traffic captured',
              style: TextStyle(color: Colors.white38, fontSize: Dimen.s14),
            ),
          );
        }
        return ListView.separated(
          controller: scrollController,
          padding: EdgeInsets.all(Dimen.w8),
          itemCount: logs.length,
          separatorBuilder: (_, _) =>
              Divider(height: Dimen.h1, color: Colors.white10),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _ApiTile(
              log: log,
              onTap: authController.isDeveloper
                  ? () => _showDetails(context, log, authController)
                  : null, // Read-only safety
            );
          },
        );
      },
    );
  }

  void _showDetails(
    BuildContext context,
    Map<String, dynamic> log,
    DevToolsAuthController authController,
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
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) =>
            _ApiDetailsSheet(log: log, scrollController: scrollController),
      ),
    );
  }
}

class _ApiTile extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback? onTap;

  const _ApiTile({required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final details = log['details'] as Map<String, dynamic>? ?? {};
    final statusCode = details['statusCode'] as int? ?? 0;
    final message = log['message'] as String? ?? '';
    final timestamp =
        (log['timestamp'] as String?)?.split('T').last.substring(0, 8) ??
        '00:00:00';

    final parts = message.split('|');
    final endpoint = parts[0].trim();
    final isSuccess = statusCode >= 200 && statusCode < 300;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: Dimen.h10,
          horizontal: Dimen.w4,
        ),
        child: Row(
          children: [
            Container(
              width: Dimen.w45,
              padding: EdgeInsets.symmetric(vertical: Dimen.h4),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimen.r4),
                border: Border.all(
                  color: isSuccess
                      ? Colors.greenAccent.withValues(alpha: 0.2)
                      : Colors.redAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  statusCode == 0 ? 'ERR' : statusCode.toString(),
                  style: TextStyle(
                    color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                    fontSize: Dimen.s12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: Dimen.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endpoint,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Dimen.s13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimen.h2),
                  Text(
                    timestamp,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Dimen.s10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.white10, size: Dimen.h16),
          ],
        ),
      ),
    );
  }
}

class _ApiDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> log;
  final ScrollController scrollController;

  const _ApiDetailsSheet({required this.log, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final details = log['details'] as Map<String, dynamic>? ?? {};
    final response = details['response'];
    final endpoint = log['message']?.toString().split('|')[0].trim();

    return Container(
      padding: EdgeInsets.all(Dimen.w16),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'API CALL DETAILS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: Dimen.s12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.copy_all,
                  color: Colors.blueAccent,
                  size: Dimen.h20,
                ),
                tooltip: 'Copy All',
                onPressed: () => _copyAll(context, endpoint, details, response),
              ),
            ],
          ),
          SizedBox(height: Dimen.h16),
          _buildInfoRow('Endpoint', endpoint, context),
          _buildInfoRow(
            'Status Code',
            details['statusCode']?.toString(),
            context,
          ),
          _buildInfoRow('Time', log['timestamp'], context),
          Divider(height: Dimen.h32, color: Colors.white10),
          _buildJsonSection('Response Payload', response, context),
        ],
      ),
    );
  }

  void _copyAll(
    BuildContext context,
    String? endpoint,
    Map<String, dynamic> details,
    dynamic response,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Endpoint: $endpoint');
    buffer.writeln('Status Code: ${details['statusCode']}');
    buffer.writeln('Time: ${log['timestamp']}');
    buffer.writeln('---');
    try {
      if (response is String) {
        final decoded = jsonDecode(response);
        buffer.writeln(const JsonEncoder.withIndent('  ').convert(decoded));
      } else {
        buffer.writeln(const JsonEncoder.withIndent('  ').convert(response));
      }
    } catch (_) {
      buffer.writeln(response?.toString() ?? 'No response');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimen.h12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
                ),
                SizedBox(height: Dimen.h4),
                SelectableText(
                  value ?? 'N/A',
                  style: TextStyle(color: Colors.white, fontSize: Dimen.s13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: Colors.white24, size: Dimen.h16),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJsonSection(String title, dynamic data, BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    String prettyJson = '';
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        prettyJson = const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {
      prettyJson = data.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
            ),
            IconButton(
              icon: Icon(Icons.copy, color: Colors.blueAccent, size: Dimen.h18),
              tooltip: 'Copy Response',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: prettyJson));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: Dimen.h8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Dimen.w12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(Dimen.r8),
            border: Border.all(color: Colors.white10),
          ),
          child: SelectableText(
            prettyJson,
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
