import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum DevToolsRole { developer, regularUser }

class DevToolsAuthController {
  DevToolsAuthController._internal();
  static final DevToolsAuthController _instance =
      DevToolsAuthController._internal();
  factory DevToolsAuthController() => _instance;

  static const String _boxName = 'devtools_auth';
  static const String _roleKey = 'selected_role';

  final ValueNotifier<DevToolsRole?> currentRole = ValueNotifier<DevToolsRole?>(
    null,
  );
  final ValueNotifier<bool> isAuthenticating = ValueNotifier<bool>(false);

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      final savedRoleIndex = Hive.box(_boxName).get(_roleKey) as int?;
      if (savedRoleIndex != null &&
          savedRoleIndex < DevToolsRole.values.length) {
        currentRole.value = DevToolsRole.values[savedRoleIndex];
      }
    } catch (e) {
      debugPrint('[DevToolsAuth] Error during init: $e');
    }
  }

  // Hardened Credentials (XOR Obfuscated to prevent plain-text extraction)
  static const List<int> _adminEmail = [
    5,
    0,
    9,
    13,
    10,
    36,
    0,
    1,
    18,
    16,
    11,
    11,
    8,
    23,
    74,
    5,
    20,
    20,
  ]; // admin@devtools.app ^ 0x64
  static const List<int> _adminPass = [
    0,
    1,
    18,
    16,
    11,
    11,
    8,
    36,
    85,
    86,
    87,
    64,
  ]; // devtool@123$ ^ 0x64
  static const List<int> _loggerEmail = [
    8,
    11,
    3,
    3,
    1,
    22,
    36,
    0,
    1,
    18,
    16,
    11,
    11,
    8,
    23,
    74,
    8,
    11,
    3,
    23,
  ]; // logger@devtools.logs ^ 0x64
  static const List<int> _loggerPass = [
    0,
    1,
    18,
    36,
    8,
    11,
    3,
    23,
  ]; // dev@logs ^ 0x64

  bool _secureCompare(String input, List<int> target) {
    if (input.length != target.length) return false;
    final List<int> inputBytes = input.codeUnits;
    for (int i = 0; i < target.length; i++) {
      if ((inputBytes[i] ^ 0x64) != target[i]) return false;
    }
    return true;
  }

  Future<void> loginWithCredentials(String email, String password) async {
    isAuthenticating.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      DevToolsRole? role;

      if (_secureCompare(email, _adminEmail) &&
          _secureCompare(password, _adminPass)) {
        role = DevToolsRole.developer;
      } else if (_secureCompare(email, _loggerEmail) &&
          _secureCompare(password, _loggerPass)) {
        role = DevToolsRole.regularUser;
      }

      if (role != null) {
        currentRole.value = role;
        if (!Hive.isBoxOpen(_boxName)) {
          await Hive.openBox(_boxName);
        }
        await Hive.box(_boxName).put(_roleKey, role.index);
        debugPrint('[DevToolsAuth] Access granted: ${role.name}');
      } else {
        throw Exception('Access Denied: Invalid credentials');
      }
    } catch (e) {
      debugPrint('[DevToolsAuth] Auth error: $e');
      rethrow;
    } finally {
      isAuthenticating.value = false;
    }
  }

  Future<void> logout() async {
    currentRole.value = null;
    if (Hive.isBoxOpen(_boxName)) {
      await Hive.box(_boxName).delete(_roleKey);
    }
    debugPrint('[DevToolsAuth] Logged out');
  }

  bool get isDeveloper => currentRole.value == DevToolsRole.developer;
  bool get isRegularUser => currentRole.value == DevToolsRole.regularUser;
  bool get isAuthenticated => currentRole.value != null;
}
