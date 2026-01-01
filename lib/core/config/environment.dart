import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String _apiUrl = '';
  static String get apiUrl => _apiUrl;

  static Future<void> load({String envFile = '.env.development'}) async {
    try {
      await dotenv.load(fileName: 'assets/.env/$envFile');
      _apiUrl = dotenv.env['API_URL'] ?? 'http://localhost';
      debugPrint('[Environment] Loaded $envFile: $_apiUrl');
    } catch (e) {
      _apiUrl = 'http://localhost';
      debugPrint(
        '[Environment] Error loading $envFile: $e. Falling back to $_apiUrl',
      );
    }
  }

  static void setCustomUrl(String url) {
    _apiUrl = url;
    debugPrint('[Environment] Custom URL set to: $_apiUrl');
  }
}
