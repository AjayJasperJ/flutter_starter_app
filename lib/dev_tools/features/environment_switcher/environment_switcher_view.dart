import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/config/environment.dart';
import '../../dev_tools_controller.dart';
import 'environment_controller.dart';

class EnvironmentSwitcherView extends StatelessWidget {
  const EnvironmentSwitcherView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EnvironmentController();
    final globalController = AppDevToolsController();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Dimen.w16,
        Dimen.w16,
        Dimen.w16,
        Dimen.w16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        const _EnvDiagnosticsCard(),
        SizedBox(height: Dimen.h24),
        Text(
          'ACTIVE ENVIRONMENT',
          style: TextStyle(
            color: Colors.white38,
            fontSize: Dimen.s11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: Dimen.h16),
        ValueListenableBuilder<String>(
          valueListenable: globalController.currentEnv,
          builder: (context, currentEnv, child) {
            return Column(
              children: [
                ...controller.availableEnvs.map(
                  (env) => _EnvTile(
                    name: env,
                    isActive: currentEnv == env,
                    onTap: () => controller.switchEnv(env),
                  ),
                ),
                if (currentEnv == 'CUSTOM') ...[
                  SizedBox(height: Dimen.h12),
                  const _CustomUrlInput(),
                ],
              ],
            );
          },
        ),
        SizedBox(height: Dimen.h24),
        const _WarningCard(),
      ],
    );
  }
}

class _EnvTile extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback onTap;

  const _EnvTile({
    required this.name,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimen.h12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(
          color: isActive ? Colors.blueAccent : Colors.white10,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        visualDensity: VisualDensity.compact,
        title: Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: Dimen.s14,
          ),
        ),
        trailing: isActive
            ? Icon(
                Icons.check_circle,
                color: Colors.blueAccent,
                size: Dimen.h20,
              )
            : Icon(
                Icons.circle_outlined,
                color: Colors.white10,
                size: Dimen.h20,
              ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimen.w16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: Dimen.h20,
          ),
          SizedBox(width: Dimen.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAUTION',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: Dimen.s12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Dimen.h4),
                Text(
                  'Switching environments will reload the app configuration. Any unsaved data might be lost.',
                  style: TextStyle(color: Colors.white70, fontSize: Dimen.s12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvDiagnosticsCard extends StatelessWidget {
  const _EnvDiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    final globalController = AppDevToolsController();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SYSTEM DIAGNOSTICS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              _buildBuildModeBadge(),
            ],
          ),
          SizedBox(height: Dimen.h16),
          Text(
            'API BASE URL',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Dimen.h4),
          ValueListenableBuilder<String>(
            valueListenable: globalController.currentEnv,
            builder: (context, _, child) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(Dimen.w10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(Dimen.r8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  Environment.apiUrl,
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBuildModeBadge() {
    String mode = 'UNKNOWN';
    Color color = Colors.grey;

    if (kDebugMode) {
      mode = 'DEBUG';
      color = Colors.redAccent;
    } else if (kProfileMode) {
      mode = 'PROFILE';
      color = Colors.orangeAccent;
    } else if (kReleaseMode) {
      mode = 'RELEASE';
      color = Colors.greenAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        mode,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CustomUrlInput extends StatefulWidget {
  const _CustomUrlInput();

  @override
  State<_CustomUrlInput> createState() => _CustomUrlInputState();
}

class _CustomUrlInputState extends State<_CustomUrlInput> {
  late TextEditingController _controller;
  final _envController = EnvironmentController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _envController.getCustomUrl());
    // Ensure the Environment is updated immediately if there's a saved URL
    if (_controller.text.isNotEmpty) {
      _envController.updateCustomUrl(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimen.w12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(Dimen.r12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOM API URL',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: Dimen.s10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: Dimen.h8),
          TextField(
            controller: _controller,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: Dimen.s13,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'https://api.example.com',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _envController.updateCustomUrl(value),
          ),
        ],
      ),
    );
  }
}
