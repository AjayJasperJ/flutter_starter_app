import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../features/logs/logs_view.dart';
import '../features/network_inspector/network_inspector_view.dart';
import '../features/environment_switcher/environment_switcher_view.dart';
import '../features/storage_explorer/storage_explorer_view.dart';
import '../features/app_info/app_info_view.dart';
import '../features/auth_tools/auth_tools_view.dart';
import '../features/quick_actions/quick_actions_view.dart';
import '../features/profile_images/profile_images_explorer_view.dart';
import '../features/auth_tools/devtools_auth_controller.dart';
import '../features/auth_tools/devtools_login_view.dart';
import '../features/feature_flags/feature_flags_view.dart';
import '../features/mocking/mock_manager_view.dart';

class DevToolsBottomSheet extends StatelessWidget {
  const DevToolsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = DevToolsAuthController();

    return ValueListenableBuilder<DevToolsRole?>(
      valueListenable: authController.currentRole,
      builder: (context, role, _) {
        if (role == null) {
          return const DevToolsLoginView();
        }

        return _DevToolsContent(role: role);
      },
    );
  }
}

class _DevToolsContent extends StatelessWidget {
  final DevToolsRole role;
  const _DevToolsContent({required this.role});

  @override
  Widget build(BuildContext context) {
    // Regular users ONLY see Logs. Developers see all 8.
    final bool isDeveloper = role == DevToolsRole.developer;
    final int tabCount = isDeveloper ? 10 : 1;

    return DefaultTabController(
      length: tabCount,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF131313),
          borderRadius: BorderRadius.vertical(top: Radius.circular(Dimen.r20)),
          border: isDeveloper
              ? Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(context),
            _buildTabBar(isDeveloper),
            Expanded(
              child: TabBarView(
                children: [
                  if (isDeveloper) ...[
                    const AppInfoView(),
                    const NetworkInspectorView(),
                    const LogsView(),
                    const StorageExplorerView(),
                    const AuthToolsView(),
                    const QuickActionsView(),
                    const MockManagerView(),
                    const EnvironmentSwitcherView(),
                    const FeatureFlagsView(),
                    const ProfileImagesExplorerView(),
                  ] else ...[
                    const LogsView(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: Dimen.h12),
      width: Dimen.w40,
      height: Dimen.h4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(Dimen.r2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authController = DevToolsAuthController();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimen.w16, vertical: Dimen.h8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimen.w6),
                decoration: BoxDecoration(
                  color: role == DevToolsRole.developer
                      ? Colors.blueAccent.withValues(alpha: 0.1)
                      : Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimen.r6),
                ),
                child: Icon(
                  role == DevToolsRole.developer
                      ? Icons.code_rounded
                      : Icons.remove_red_eye_outlined,
                  size: Dimen.h16,
                  color: role == DevToolsRole.developer
                      ? Colors.blueAccent
                      : Colors.orangeAccent,
                ),
              ),
              SizedBox(width: Dimen.w8),
              Text(
                role == DevToolsRole.developer
                    ? "DEVELOPER MODE"
                    : "REGULAR USER",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: Dimen.s12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => authController.logout(),
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.white38,
              size: Dimen.h20,
            ),
            tooltip: "Switch Role",
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDeveloper) {
    if (!isDeveloper) {
      return const SizedBox.shrink();
    }

    return TabBar(
      isScrollable: true,
      indicatorColor: Colors.blueAccent,
      labelColor: Colors.blueAccent,
      unselectedLabelColor: Colors.white38,
      indicatorSize: TabBarIndicatorSize.label,
      tabAlignment: TabAlignment.start,
      padding: EdgeInsets.symmetric(horizontal: Dimen.w8),
      tabs: const [
        Tab(text: 'Info', icon: Icon(Icons.info_outline)),
        Tab(text: 'Network', icon: Icon(Icons.network_check)),
        Tab(text: 'Logs', icon: Icon(Icons.list_alt)),
        Tab(text: 'Storage', icon: Icon(Icons.storage_rounded)),
        Tab(text: 'Auth', icon: Icon(Icons.lock_outline)),
        Tab(text: 'Actions', icon: Icon(Icons.bolt)),
        Tab(text: 'Mocks', icon: Icon(Icons.theater_comedy)),
        Tab(text: 'Env', icon: Icon(Icons.settings)),
        Tab(text: 'Flags', icon: Icon(Icons.flag_outlined)),
        Tab(text: 'Image Cache', icon: Icon(Icons.image_outlined)),
      ],
    );
  }
}
