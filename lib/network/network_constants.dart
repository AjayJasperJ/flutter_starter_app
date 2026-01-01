class NetworkConstants {
  // Hive Box Names
  static const String cacheBox = 'api_cache';
  static const String offlineQueueBox = 'offline_queue';
  static const String refreshQueueBox = 'refresh_queue';

  // API Config
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static const Duration maxCacheAge = Duration(days: 30);
}
