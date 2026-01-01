import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyRefreshToken = 'refresh_token';

  static Future<void> saveToken(String token, String refreshToken) async {
    updatelogged(true);
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static final StreamController<void> _logoutController = StreamController<void>.broadcast();
  static Stream<void> get logoutStream => _logoutController.stream;

  static Future<void> deleteToken() async {
    updatelogged(false);
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    _logoutController.add(null);
  }

  static bool _loggedUser = false;
  static bool get logged => _loggedUser;

  static void updatelogged(bool value) {
    _loggedUser = value;
  }
}
