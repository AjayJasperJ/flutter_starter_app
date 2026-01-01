import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ThrottlingProfile {
  none('None (Real Speed)', 'OFF', 0),
  edge('EDGE (Slow)', 'EDGE', 2000),
  twoG('2G (Limited)', '2G', 1500),
  threeG('3G (Balanced)', '3G', 700),
  fourG('4G (Normal)', '4G', 100),
  fiveG('5G (Low Latency)', '5G', 10);

  final String label;
  final String shortLabel;
  final int latencyMs;
  const ThrottlingProfile(this.label, this.shortLabel, this.latencyMs);
}

class NetworkThrottlingController {
  NetworkThrottlingController._internal();
  static final NetworkThrottlingController _instance =
      NetworkThrottlingController._internal();
  factory NetworkThrottlingController() => _instance;

  static const String _boxName = 'devtools_network_throttling';
  static const String _profileKey = 'active_profile';

  final ValueNotifier<ThrottlingProfile> activeProfile =
      ValueNotifier<ThrottlingProfile>(ThrottlingProfile.none);

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    final box = Hive.box(_boxName);
    final profileName = box.get(
      _profileKey,
      defaultValue: ThrottlingProfile.none.name,
    );

    activeProfile.value = ThrottlingProfile.values.firstWhere(
      (p) => p.name == profileName,
      orElse: () => ThrottlingProfile.none,
    );

    debugPrint(
      '[ThrottlingController] Initialized with: ${activeProfile.value.label}',
    );
  }

  Future<void> setProfile(ThrottlingProfile profile) async {
    final box = Hive.box(_boxName);
    await box.put(_profileKey, profile.name);
    activeProfile.value = profile;
    debugPrint('[ThrottlingController] Set Profile: ${profile.label}');
  }
}
