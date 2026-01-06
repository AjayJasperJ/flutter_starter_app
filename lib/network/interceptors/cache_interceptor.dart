import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../network_constants.dart';
import '../utils/connectivity_service.dart';
import '../utils/network_utils.dart';

class CacheInterceptor extends Interceptor {
  final Box _cacheBox;
  static const Duration maxCacheAge = Duration(days: NetworkConstants.defaultCacheDurationDays);
  static const int maxItems = NetworkConstants.maxCacheItems; // LRU Item Limit

  CacheInterceptor(this._cacheBox);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Only cache GET requests
    if (options.method != 'GET') {
      return handler.next(options);
    }

    // Check disableCache flag
    if (options.extra['disableCache'] == true) {
      return handler.next(options);
    }

    // If we have internet, proceed to network
    bool isOnline = ConnectivityService().hasConnection;
    if (isOnline) {
      return handler.next(options);
    }

    // If offline, check cache
    final key = options.uri.toString();
    final cachedEntry = _cacheBox.get(key);

    if (cachedEntry != null && cachedEntry is Map) {
      final timestampStr = cachedEntry['timestamp'] as String?;
      final lastAccessedStr = cachedEntry['lastAccessed'] as String?;
      final storageDurationMs = cachedEntry['storageDurationMs'] as int?;

      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final lastAccessed = lastAccessedStr != null ? DateTime.parse(lastAccessedStr) : timestamp;
        final now = DateTime.now();

        // Use stored duration if available, otherwise default to maxCacheAge
        final entryMaxAge = storageDurationMs != null
            ? Duration(milliseconds: storageDurationMs)
            : maxCacheAge;

        // Check expiry based on specific entry duration
        if (now.difference(timestamp) > entryMaxAge || now.difference(lastAccessed) > entryMaxAge) {
          debugPrint('[CACHE] Purging expired data for: $key (Limit: ${entryMaxAge.inMinutes}m)');
          _cacheBox.delete(key);
          return handler.next(options);
        }

        // Update last accessed timestamp
        _cacheBox.put(key, {
          ...Map<String, dynamic>.from(cachedEntry),
          'lastAccessed': now.toIso8601String(),
        });
      }

      final data = cachedEntry['data'];

      debugPrint('[CACHE] Serving offline data for: $key (cached at: $timestampStr)');

      return handler.resolve(
        Response(
          requestOptions: options,
          data: data,
          statusCode: 200,
          statusMessage: 'OK (Cached)',
          extra: Map.from(options.extra)..['isFromCache'] = true,
        ),
      );
    } else {
      // No cache and no internet
      return handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check disableCache flag first
    if (err.requestOptions.extra['disableCache'] == true) {
      return handler.next(err);
    }

    // Network-first, fallback to cache strategy
    if (err.requestOptions.method == 'GET' && _isNetworkError(err)) {
      final key = err.requestOptions.uri.toString();
      final cachedEntry = _cacheBox.get(key);

      debugPrint('[CACHE DEBUG] Network Error Type: ${err.type}');
      debugPrint('[CACHE DEBUG] Error Message: ${err.message}');
      debugPrint('[CACHE DEBUG] Key: $key');
      debugPrint('[CACHE DEBUG] Cache Exists: ${cachedEntry != null}');

      if (cachedEntry != null && cachedEntry is Map) {
        final timestampStr = cachedEntry['timestamp'] as String?;
        final lastAccessedStr = cachedEntry['lastAccessed'] as String?;
        final storageDurationMs = cachedEntry['storageDurationMs'] as int?;

        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          final lastAccessed = lastAccessedStr != null
              ? DateTime.parse(lastAccessedStr)
              : timestamp;
          final now = DateTime.now();

          final entryMaxAge = storageDurationMs != null
              ? Duration(milliseconds: storageDurationMs)
              : maxCacheAge;

          if (now.difference(timestamp) > entryMaxAge ||
              now.difference(lastAccessed) > entryMaxAge) {
            debugPrint(
              '[CACHE] Purging expired data (onError) for: $key (Limit: ${entryMaxAge.inMinutes}m)',
            );
            _cacheBox.delete(key);
            return super.onError(err, handler);
          }

          // Update last accessed timestamp
          _cacheBox.put(key, {
            ...Map<String, dynamic>.from(cachedEntry),
            'lastAccessed': now.toIso8601String(),
          });
        }

        final data = cachedEntry['data'];

        debugPrint(
          '[CACHE] Network failed. Serving cached data for: $key (cached at: $timestampStr)',
        );

        // Hive often returns Map<dynamic, dynamic>, but Dio/Freezed expects Map<String, dynamic>
        final castData = NetworkUtils.castToMapStringDynamic(data);

        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: castData,
            statusCode: 200,
            statusMessage: 'OK (Cached Fallback)',
            extra: Map.from(err.requestOptions.extra)..['isFromCache'] = true,
          ),
        );
      } else {
        debugPrint('[CACHE] No cache found for $key');
      }
    } else {
      debugPrint(
        '[CACHE DEBUG] Fallback skipped. Method: ${err.requestOptions.method}, IsNetworkError: ${_isNetworkError(err)}',
      );
    }
    super.onError(err, handler);
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.unknown ||
        (err.error != null && err.error.toString().toLowerCase().contains('socket'));
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check disableCache flag
    if (response.requestOptions.extra['disableCache'] == true) {
      return handler.next(response);
    }

    // Save successful GET responses to cache with timestamp
    if (response.requestOptions.method == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final key = response.requestOptions.uri.toString();
      final now = DateTime.now().toIso8601String();

      final Duration? cacheDuration = response.requestOptions.extra['cacheStorageDuration'];
      final Map<String, dynamic> cacheEntry = {
        'data': response.data,
        'timestamp': now,
        'lastAccessed': now,
      };

      if (cacheDuration != null) {
        cacheEntry['storageDurationMs'] = cacheDuration.inMilliseconds;
      }

      // Store data with creation timestamp and lastAccessed
      _cacheBox.put(key, cacheEntry);

      _performLRU();
    }
    super.onResponse(response, handler);
  }

  /// Keep box size under maxItems by removing old entries
  void _performLRU() {
    if (_cacheBox.length <= maxItems) return;

    final sortedKeys = _cacheBox.keys.toList()
      ..sort((a, b) {
        final entryA = _cacheBox.get(a) as Map?;
        final entryB = _cacheBox.get(b) as Map?;
        final timeA = entryA?['lastAccessed'] as String? ?? '';
        final timeB = entryB?['lastAccessed'] as String? ?? '';
        return timeA.compareTo(timeB);
      });

    final keysToRemove = sortedKeys.take(_cacheBox.length - maxItems);
    _cacheBox.deleteAll(keysToRemove);
    debugPrint('[CACHE] LRU evicted ${keysToRemove.length} items.');
  }

  /// Bulk prune expired cache entries
  Future<void> pruneCache() async {
    if (_cacheBox.isEmpty) return;
    final now = DateTime.now();
    final keysToDelete = <dynamic>[];
    for (final key in _cacheBox.keys) {
      final entry = _cacheBox.get(key);
      if (entry is Map) {
        final timestampStr = entry['timestamp'] as String?;
        final lastAccessedStr = entry['lastAccessed'] as String?;
        final storageDurationMs = entry['storageDurationMs'] as int?;

        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          final lastAccessed = lastAccessedStr != null
              ? DateTime.parse(lastAccessedStr)
              : timestamp;

          final entryMaxAge = storageDurationMs != null
              ? Duration(milliseconds: storageDurationMs)
              : maxCacheAge;

          if (now.difference(timestamp) > entryMaxAge ||
              now.difference(lastAccessed) > entryMaxAge) {
            keysToDelete.add(key);
          }
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      debugPrint('[CACHE] Pruning ${keysToDelete.length} expired entries.');
      await _cacheBox.deleteAll(keysToDelete);
    }
  }
}
