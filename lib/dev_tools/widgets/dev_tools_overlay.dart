import 'package:flutter/material.dart';
import '../dev_tools_controller.dart';
import 'dev_tools_bottom_sheet.dart';
// External dependency - required for navigation
import '../../../routes/route_services.dart';

class DevToolsOverlay extends StatelessWidget {
  final Widget child;
  const DevToolsOverlay({super.key, required this.child});

  static final ValueNotifier<Offset> _offset = ValueNotifier(
    const Offset(20, 100),
  );
  static final ValueNotifier<bool> _isSheetOpen = ValueNotifier(false);
  static NavigatorState? _sheetNavigator;

  @override
  Widget build(BuildContext context) {
    final controller = AppDevToolsController();
    if (!controller.enabled) return child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          ValueListenableBuilder<Offset>(
            valueListenable: _offset,
            builder: (context, offset, _) {
              return Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _offset.value += details.delta;
                  },
                  onTap: () => _toggleDevTools(),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.developer_mode_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static void _toggleDevTools() {
    // If sheet is open, close it
    if (_isSheetOpen.value) {
      _sheetNavigator?.pop();
      return;
    }

    // Otherwise, open it
    final context = RouteServices.navigatorKey.currentContext;
    if (context != null) {
      _isSheetOpen.value = true;
      _sheetNavigator = Navigator.of(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const DevToolsBottomSheet(),
      ).whenComplete(() {
        _isSheetOpen.value = false;
        _sheetNavigator = null;
      });
    }
  }
}
