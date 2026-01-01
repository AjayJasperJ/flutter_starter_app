import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/dimensions.dart';
import '../../dev_tools_controller.dart';

class AppInfoView extends StatelessWidget {
  const AppInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppDevToolsController();
    final mediaQuery = MediaQuery.of(context);

    return ListView(
      padding: EdgeInsets.all(Dimen.w16),
      children: [
        BuildSection('Device Information', [
          _InfoRow(label: 'Platform', value: _getPlatform()),
          ValueListenableBuilder<String>(
            valueListenable: controller.deviceBrand,
            builder: (context, val, _) => _InfoRow(label: 'Brand', value: val),
          ),
          ValueListenableBuilder<String>(
            valueListenable: controller.deviceModel,
            builder: (context, val, _) => _InfoRow(label: 'Model', value: val),
          ),
          _InfoRow(label: 'OS Version', value: Platform.operatingSystemVersion),
          _InfoRow(
            label: 'Screen Size',
            value:
                '${mediaQuery.size.width.toInt()} x ${mediaQuery.size.height.toInt()}',
          ),
        ]),
        SizedBox(height: Dimen.h16),
        BuildSection('App Information', [
          ValueListenableBuilder<String>(
            valueListenable: controller.appName,
            builder: (context, val, _) =>
                _InfoRow(label: 'App Name', value: val),
          ),
          ValueListenableBuilder<String>(
            valueListenable: controller.version,
            builder: (context, val, _) =>
                _InfoRow(label: 'Version', value: val),
          ),
          ValueListenableBuilder<String>(
            valueListenable: controller.buildNumber,
            builder: (context, val, _) => _InfoRow(label: 'Build', value: val),
          ),
          ValueListenableBuilder<String>(
            valueListenable: controller.packageName,
            builder: (context, val, _) =>
                _InfoRow(label: 'Package', value: val),
          ),
        ]),
        SizedBox(height: Dimen.h16),
        BuildSection('Environment', [
          ValueListenableBuilder<String>(
            valueListenable: controller.currentEnv,
            builder: (context, env, _) {
              return _InfoRow(label: 'Current Env', value: env);
            },
          ),
          _InfoRow(label: 'Debug Mode', value: kDebugMode ? 'Yes' : 'No'),
          _InfoRow(label: 'Release Mode', value: kReleaseMode ? 'Yes' : 'No'),
        ]),
        SizedBox(height: Dimen.h16),
        BuildSection('Connectivity', [
          ValueListenableBuilder<String>(
            valueListenable: controller.connectionType,
            builder: (context, val, _) =>
                _InfoRow(label: 'Connection', value: val),
          ),
          ValueListenableBuilder<String>(
            valueListenable: controller.localIP,
            builder: (context, val, _) =>
                _InfoRow(label: 'Local IP', value: val),
          ),
        ]),
        SizedBox(height: Dimen.h16),
        BuildSection('Runtime', [
          _InfoRow(
            label: 'Dart Version',
            value: Platform.version.split(' ').first,
          ),
          _InfoRow(label: 'Locale', value: Platform.localeName),
          _InfoRow(
            label: 'Processors',
            value: Platform.numberOfProcessors.toString(),
          ),
        ]),
      ],
    );
  }

  String _getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

class BuildSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const BuildSection(this.title, this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimen.w16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white38,
              fontSize: Dimen.s11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: Dimen.h12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimen.h6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: Dimen.s13),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: Dimen.s13,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
