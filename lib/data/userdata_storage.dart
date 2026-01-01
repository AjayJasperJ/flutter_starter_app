import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserdataStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _encryptionkey = 'encryptedUser';

  static Future<void> saveUserData(String token) async {
    await _storage.write(key: _encryptionkey, value: token);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _encryptionkey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _encryptionkey);
  }
}
