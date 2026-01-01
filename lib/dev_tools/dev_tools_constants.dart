import 'package:flutter/foundation.dart';

class DevToolsConstants {
  /// Universal flag to control inclusion of DevTools.
  /// Defaults to true in Debug/Profile modes and false in Release.
  /// Can be overridden via: --dart-define=INCLUDE_DEVTOOLS=true/false
  static const bool kIncludeDevTools = bool.fromEnvironment(
    'INCLUDE_DEVTOOLS',
    defaultValue: !kReleaseMode,
  );

  /// Helper to check if DevTools features should be active.
  static bool get shouldEnable => kIncludeDevTools;
}
