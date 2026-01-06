class NetworkConstants {
  // Timeouts
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
  static const int sendTimeoutSeconds = 30;

  // Cache
  static const int defaultCacheDurationDays = 30;
  static const int maxCacheItems = 200;

  // Retries
  static const int maxRetries = 3;
  static const List<int> retryDelaysSeconds = [1, 2, 3];
}
