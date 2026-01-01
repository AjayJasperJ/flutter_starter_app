import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FeatureFlagController {
  FeatureFlagController._internal();
  static final FeatureFlagController _instance =
      FeatureFlagController._internal();
  factory FeatureFlagController() => _instance;

  static const String _boxName = 'devtools_feature_flags';

  // Default Flags
  final Map<String, bool> _defaultFlags = {
    'Experimental UI': false,
    'Beta Payment Flow': false,
    'Advanced Networking': true,
    'Deep Logging': false,
    'Mock API Responses': false,
  };

  final ValueNotifier<Map<String, bool>> flags =
      ValueNotifier<Map<String, bool>>({});

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    final box = Hive.box(_boxName);
    final Map<String, bool> currentFlags = {};

    for (var entry in _defaultFlags.entries) {
      currentFlags[entry.key] =
          box.get(entry.key, defaultValue: entry.value) as bool;
    }

    flags.value = currentFlags;
    debugPrint('[FeatureFlags] Initialized with ${currentFlags.length} flags');
  }

  Future<void> setFlag(String name, bool value) async {
    final box = Hive.box(_boxName);
    await box.put(name, value);

    final newFlags = Map<String, bool>.from(flags.value);
    newFlags[name] = value;
    flags.value = newFlags;
    debugPrint('[FeatureFlags] Toggle: $name -> $value');
  }

  bool isEnabled(String name) => flags.value[name] ?? false;
}
