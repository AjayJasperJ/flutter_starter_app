import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/config/environment.dart';
import '../../dev_tools_controller.dart';

class EnvironmentController {
  EnvironmentController._internal();
  static final EnvironmentController _instance =
      EnvironmentController._internal();
  factory EnvironmentController() => _instance;

  static const String _boxName = 'devtools_settings';
  static const String _envKey = 'selected_environment';
  static const String _customUrlKey = 'custom_env_url';

  final List<String> availableEnvs = [
    'Development',
    'Staging',
    'Production',
    'CUSTOM',
  ];

  /// Initialize and load saved environment
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      final savedEnv = getSavedEnv();
      if (savedEnv != null && availableEnvs.contains(savedEnv)) {
        await switchEnv(savedEnv, isInit: true);
      }
    } catch (e) {
      debugPrint('[EnvController] Error initializing: $e');
    }
  }

  /// Get saved environment from Hive
  String? getSavedEnv() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box(_boxName).get(_envKey) as String?;
      }
    } catch (e) {
      debugPrint('[EnvController] Error reading saved env: $e');
    }
    return null;
  }

  /// Get saved custom URL
  String getCustomUrl() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box(_boxName).get(_customUrlKey, defaultValue: '')
            as String;
      }
    } catch (e) {
      debugPrint('[EnvController] Error reading custom URL: $e');
    }
    return '';
  }

  /// Save custom URL
  Future<void> updateCustomUrl(String url) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      await Hive.box(_boxName).put(_customUrlKey, url);
      Environment.setCustomUrl(url);
      debugPrint('[EnvController] Updated custom URL: $url');
    } catch (e) {
      debugPrint('[EnvController] Error saving custom URL: $e');
    }
  }

  /// Save environment to Hive
  Future<void> _saveEnv(String env) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      await Hive.box(_boxName).put(_envKey, env);
      debugPrint('[EnvController] Saved environment: $env');
    } catch (e) {
      debugPrint('[EnvController] Error saving env: $e');
    }
  }

  /// Switch environment and persist
  Future<void> switchEnv(String env, {bool isInit = false}) async {
    AppDevToolsController().setEnv(env);

    if (env == 'CUSTOM') {
      // For custom, we default to dev env vars but override the URL
      await Environment.load(envFile: '.env.development');
      final customUrl = getCustomUrl();
      if (customUrl.isNotEmpty) {
        Environment.setCustomUrl(customUrl);
      }
    } else {
      // Mapping display names to file names
      final envMap = {
        'Development': '.env.development',
        'Staging': '.env.staging',
        'Production': '.env.production',
      };

      final fileName = envMap[env] ?? '.env.development';
      await Environment.load(envFile: fileName);
    }

    // Save to Hive
    await _saveEnv(env);

    debugPrint(
      '[EnvController] Switched to: $env (URL: ${Environment.apiUrl})${isInit ? ' [restored]' : ''}',
    );
  }
}
