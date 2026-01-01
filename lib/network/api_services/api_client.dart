import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:convert';
import '../../../core/config/environment.dart';
import '../../../data/token_storage.dart';
import 'api_error.dart';
import 'api_response.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/cache_interceptor.dart';
import '../interceptors/logger_interceptor.dart';
import '../interceptors/offline_sync_interceptor.dart';
import '../interceptors/performance_interceptor.dart';
import '../interceptors/mock_interceptor.dart';
import '../interceptors/throttling_interceptor.dart';
import '../../dev_tools/dev_tools_constants.dart';
import '../utils/connectivity_service.dart';
import '../network_constants.dart';
import '../interceptors/circuit_breaker_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  // Global broadcast for successful re-fetches
  static final StreamController<String> _refreshController =
      StreamController<String>.broadcast();
  static Stream<String> get refreshStream => _refreshController.stream;

  // Track paths that were served from cache and need background refresh upon reconnection
  Box? _refreshBox;

  // Track keys that have been successfully fetched from network during this app session
  static final Set<String> _sessionFetchedKeys = {};

  // Track in-flight requests for deduplication
  final Map<String, Future<ApiResult<Response>>> _inFlightRequests = {};

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal({String? baseUrl, Dio? dioOverride, Duration? timeout}) {
    final effectiveBaseUrl = _normalizeBase(baseUrl ?? Environment.apiUrl);
    debugPrint(
      '[ApiClient] Initializing with baseUrl: "$effectiveBaseUrl" (Source: ${baseUrl ?? 'Environment.apiUrl'})',
    );

    _dio =
        dioOverride ??
        Dio(
          BaseOptions(
            baseUrl: effectiveBaseUrl,
            connectTimeout: timeout ?? NetworkConstants.connectTimeout,
            receiveTimeout: timeout ?? NetworkConstants.receiveTimeout,
            sendTimeout: timeout ?? NetworkConstants.sendTimeout,
            headers: NetworkConstants.defaultHeaders,
          ),
        );

    Box? cacheBox;
    Box? queueBox;
    if (Hive.isBoxOpen(NetworkConstants.cacheBox)) {
      cacheBox = Hive.box(NetworkConstants.cacheBox);
    }
    if (Hive.isBoxOpen(NetworkConstants.offlineQueueBox)) {
      queueBox = Hive.box(NetworkConstants.offlineQueueBox);
    }
    if (Hive.isBoxOpen(NetworkConstants.refreshQueueBox)) {
      _refreshBox = Hive.box(NetworkConstants.refreshQueueBox);
    }

    if (cacheBox != null) {
      final cacheInterceptor = CacheInterceptor(cacheBox);
      _dio.interceptors.add(cacheInterceptor);
      cacheInterceptor.pruneCache(); // Async cleanup on startup
    }
    if (queueBox != null) {
      _dio.interceptors.add(
        OfflineSyncInterceptor(dio: _dio, queueBox: queueBox),
      );
    }
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: debugPrint,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, attempt) {
          if (error.type == DioExceptionType.connectionError) {
            return false;
          }
          final retryableStatuses = {429};
          final retryableTypes = {
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
          };
          return retryableStatuses.contains(error.response?.statusCode) ||
              retryableTypes.contains(error.type);
        },
      ),
    );
    _dio.interceptors.add(PerformanceInterceptor());
    _dio.interceptors.add(CircuitBreakerInterceptor());
    if (DevToolsConstants.kIncludeDevTools) {
      _dio.interceptors.add(ThrottlingInterceptor());
      _dio.interceptors.add(
        MockInterceptor(),
      ); // Mocking should have high precedence
    }
    _dio.interceptors.add(LoggerInterceptor());
    _dio.interceptors.add(AuthInterceptor(dio: _dio));

    ConnectivityService().connectionChange.listen((hasConnection) async {
      if (hasConnection) {
        await Future.delayed(const Duration(seconds: 2));
        await syncOfflineData();

        // 3. Automatically refresh cached GET paths from persistent queue
        if (_refreshBox != null && _refreshBox!.isNotEmpty) {
          final pathsToRefresh = _refreshBox!.values.cast<String>().toList();
          for (final path in pathsToRefresh) {
            // Sequential batching with delay to prevent thundering herd
            await Future.delayed(const Duration(milliseconds: 300));
            // staleWhileRevalidate: false here because we ARE the revalidator
            await get(path, withAuth: true, staleWhileRevalidate: false);

            // Remove from queue after successful (or attempted) refresh
            await _refreshBox!.deleteAt(0);
          }
        }
      }
    });

    // 4. Initial check: If app starts online, refresh pending paths
    Future.microtask(() async {
      if (ConnectivityService().hasConnection) {
        await syncOfflineData();
        if (_refreshBox != null && _refreshBox!.isNotEmpty) {
          final pathsToRefresh = _refreshBox!.values.cast<String>().toList();
          for (final path in pathsToRefresh) {
            await Future.delayed(const Duration(milliseconds: 300));
            await get(path, withAuth: true, staleWhileRevalidate: false);
            if (_refreshBox!.isNotEmpty) await _refreshBox!.deleteAt(0);
          }
        }
      }
    });
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Manually reset the session cache for a specific path or all paths.
  /// If [path] is provided, only that path is removed from the session cache.
  /// If [path] is null, the entire session cache is cleared.
  static void resetSessionStale({String? path}) {
    if (path != null) {
      debugPrint('[NETWORK] Resetting session stale for path: $path');
      // Remove all keys that match the pattern "GET:path:..."
      _sessionFetchedKeys.removeWhere((key) => key.startsWith('GET:$path:'));
    } else {
      debugPrint('[NETWORK] Resetting all session stale keys');
      _sessionFetchedKeys.clear();
    }
  }

  Future<ApiResult<Response>> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withAuth = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(headers: headers, extra: {'withAuth': withAuth}),
      );
      return ApiResult.success(response);
    } on DioException catch (e) {
      return ApiResult.failure(ErrorHandler.handle(e));
    } catch (e) {
      return ApiResult.failure(
        ApiError(message: "Unexpected error: $e", type: ApiErrorType.unknown),
      );
    }
  }

  Future<ApiResult<Response>> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withAuth = true,
    bool staleWhileRevalidate = true,
    bool sessionStale = true,
    bool resetCurrentStale = false,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final requestKey = 'GET:$path:${query?.toString()}';

    // 1. Request Deduplication: Return existing future if same request is in-flight
    if (_inFlightRequests.containsKey(requestKey)) {
      debugPrint('[NETWORK] Deduplicating request: $path');
      return _inFlightRequests[requestKey]!;
    }

    // 2. Reset Current Stale: Force invalidation for this specific request key
    if (resetCurrentStale) {
      debugPrint(
        '[NETWORK] ResetCurrentStale: Invalidating session cache for $path',
      );
      _sessionFetchedKeys.remove(requestKey);
    }

    // 3. Session-Based Stale Handling
    // If we've already fetched this in the current session, return from cache immediately
    // and skip the network request to avoid unwanted traffic.
    if (sessionStale && _sessionFetchedKeys.contains(requestKey)) {
      final cachedResponse = await _checkCache(path, query: query);
      if (cachedResponse != null) {
        debugPrint(
          '[NETWORK] SessionStale: Returning cached data for $path (Session Active)',
        );
        return ApiResult.success(cachedResponse);
      }
    }

    final future = _getInternal(
      path,
      query: query,
      headers: headers,
      withAuth: withAuth,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );

    _inFlightRequests[requestKey] = future;

    try {
      // 4. Classic Stale-While-Revalidate: If we have cache, return it immediately
      // and let the network future complete in background.
      // We skip this if we are in "First Load" mode of sessionStale (not in _sessionFetchedKeys)
      // because we want the first load to be fresh.
      final shouldServeSWR =
          staleWhileRevalidate &&
          (!sessionStale || _sessionFetchedKeys.contains(requestKey));

      if (shouldServeSWR) {
        final cachedResponse = await _checkCache(path, query: query);
        if (cachedResponse != null) {
          debugPrint('[NETWORK] SWR: Returning cached data for $path');

          // Allow the background future to continue and clean up itself
          future.then((result) {
            if (result.isSuccess) {
              _sessionFetchedKeys.add(requestKey);
            }
            _inFlightRequests.remove(requestKey);
          });

          return ApiResult.success(cachedResponse);
        }
      }

      final result = await future;

      // If network request was successful, mark this key as "fetched in session"
      if (result.isSuccess) {
        _sessionFetchedKeys.add(requestKey);
      }

      return result;
    } finally {
      // Clean up in-flight mapping if we didn't return early
      if (_inFlightRequests.containsKey(requestKey)) {
        _inFlightRequests.remove(requestKey);
      }
    }
  }

  Future<Response?> _checkCache(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final cacheBox = Hive.isBoxOpen(NetworkConstants.cacheBox)
        ? Hive.box(NetworkConstants.cacheBox)
        : null;
    if (cacheBox == null) return null;

    // Build the same key as CacheInterceptor (Full URI)
    final options = RequestOptions(
      baseUrl: _dio.options.baseUrl,
      path: path,
      queryParameters: query,
    );
    final key = options.uri.toString();

    final cachedEntry = cacheBox.get(key);
    if (cachedEntry != null && cachedEntry is Map) {
      final data = cachedEntry['data'];
      final decodedData = data is String
          ? await compute(_parseJson, data)
          : data;

      return Response(
        requestOptions: options,
        data: decodedData,
        statusCode: 200,
        extra: {'isFromCache': true, 'timestamp': cachedEntry['timestamp']},
      );
    }
    return null;
  }

  Future<ApiResult<Response>> _getInternal(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withAuth = true,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth},
          responseType: ResponseType.plain,
        ),
      );

      final isFromCache = response.extra['isFromCache'] ?? false;

      // 2. Background JSON Parsing (Isolates)
      if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final decodedData = await compute(
            _parseJson,
            response.data as String,
          );
          response.data = decodedData;
        } catch (e) {
          debugPrint('[NETWORK] Isolate parsing failed: $e');
          // Fallback to main thread if isolate fails for some reason
          response.data = jsonDecode(response.data as String);
        }
      }

      if (isFromCache) {
        // Persistent Registry: Record that this path needs a refresh when online
        if (_refreshBox != null && !ConnectivityService().hasConnection) {
          if (!_refreshBox!.values.contains(path)) {
            _refreshBox!.add(path);
          }
        }
      } else {
        // If it was previously in the refresh queue but now came from network,
        // remove it and broadcast fresh data
        if (_refreshBox != null) {
          final keysToRemove = _refreshBox!.keys
              .where((k) => _refreshBox!.get(k) == path)
              .toList();
          for (final k in keysToRemove) {
            _refreshBox!.delete(k);
          }
        }
        _refreshController.add(path);
      }

      return ApiResult.success(response);
    } on DioException catch (e) {
      return ApiResult.failure(ErrorHandler.handle(e));
    } catch (e) {
      return ApiResult.failure(
        ApiError(message: "Unexpected error: $e", type: ApiErrorType.unknown),
      );
    }
  }

  Future<ApiResult<Response>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withAuth = true,
    bool isOfflineSync = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth, 'isOfflineSync': isOfflineSync},
          responseType: ResponseType.plain,
        ),
      );

      // Background JSON Parsing (Isolates)
      if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final decodedData = await compute(
            _parseJson,
            response.data as String,
          );
          response.data = decodedData;
        } catch (e) {
          debugPrint('[NETWORK] POST Isolate parsing failed: $e');
          response.data = jsonDecode(response.data as String);
        }
      }

      return ApiResult.success(response);
    } on DioException catch (e) {
      return ApiResult.failure(ErrorHandler.handle(e));
    } catch (e) {
      return ApiResult.failure(
        ApiError(message: "Unexpected error: $e", type: ApiErrorType.unknown),
      );
    }
  }

  Future<ApiResult<Response>> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withAuth = true,
    bool isOfflineSync = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth, 'isOfflineSync': isOfflineSync},
          responseType: ResponseType.plain,
        ),
      );

      // Background JSON Parsing (Isolates)
      if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final decodedData = await compute(
            _parseJson,
            response.data as String,
          );
          response.data = decodedData;
        } catch (e) {
          debugPrint('[NETWORK] PUT Isolate parsing failed: $e');
          response.data = jsonDecode(response.data as String);
        }
      }

      return ApiResult.success(response);
    } on DioException catch (e) {
      return ApiResult.failure(ErrorHandler.handle(e));
    } catch (e) {
      return ApiResult.failure(
        ApiError(message: "Unexpected error: $e", type: ApiErrorType.unknown),
      );
    }
  }

  Future<ApiResult<Response>> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool withAuth = true,
    bool isOfflineSync = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: headers,
          extra: {'withAuth': withAuth, 'isOfflineSync': isOfflineSync},
          responseType: ResponseType.plain,
        ),
      );

      // Background JSON Parsing (Isolates)
      if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final decodedData = await compute(
            _parseJson,
            response.data as String,
          );
          response.data = decodedData;
        } catch (e) {
          debugPrint('[NETWORK] DELETE Isolate parsing failed: $e');
          response.data = jsonDecode(response.data as String);
        }
      }

      return ApiResult.success(response);
    } on DioException catch (e) {
      return ApiResult.failure(ErrorHandler.handle(e));
    } catch (e) {
      return ApiResult.failure(
        ApiError(message: "Unexpected error: $e", type: ApiErrorType.unknown),
      );
    }
  }

  Future<ApiResult<Response>> multipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? filePaths,
    List<MultipartBytesFile>? files,
    Map<String, String>? headers,
    bool withAuth = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final formData = FormData();

      if (fields != null) {
        fields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value));
        });
      }

      if (filePaths != null && !kIsWeb) {
        for (final entry in filePaths.entries) {
          formData.files.add(
            MapEntry(entry.key, await MultipartFile.fromFile(entry.value)),
          );
        }
      }

      if (files != null) {
        for (final f in files) {
          formData.files.add(
            MapEntry(
              f.field,
              MultipartFile.fromBytes(
                f.bytes,
                filename: f.filename,
                contentType: f.contentType,
              ),
            ),
          );
        }
      }

      final response = await _dio.post(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth},
          responseType: ResponseType.plain,
        ),
      );

      // Background JSON Parsing (Isolates)
      if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final decodedData = await compute(
            _parseJson,
            response.data as String,
          );
          response.data = decodedData;
        } catch (e) {
          debugPrint('[NETWORK] MULTIPART Isolate parsing failed: $e');
          response.data = jsonDecode(response.data as String);
        }
      }

      return ApiResult.success(response);
    } on DioException catch (e) {
      return ApiResult.failure(ErrorHandler.handle(e));
    } catch (e) {
      return ApiResult.failure(
        ApiError(message: "Unexpected error: $e", type: ApiErrorType.unknown),
      );
    }
  }

  static String _normalizeBase(String base) {
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  static Future<void> authguard(
    int? statusCode, {
    bool forceLogout = false,
  }) async {
    if (forceLogout || statusCode == 401) {
      await TokenStorage.deleteToken();
    }
  }

  Future<void> syncOfflineData() async {
    for (final interceptor in _dio.interceptors) {
      if (interceptor is OfflineSyncInterceptor) {
        await interceptor.syncQueue();
      }
    }
  }

  void dispose() {
    _dio.close();
  }
}

/// Standalone function for Isolate JSON parsing
dynamic _parseJson(String text) {
  return jsonDecode(text);
}

class MultipartBytesFile {
  const MultipartBytesFile({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });
  final String field;
  final List<int> bytes;
  final String filename;
  final MediaType? contentType;
}

class HttpRequestException implements Exception {
  HttpRequestException(this.message, {this.isNetwork = false});
  final String message;
  final bool isNetwork;
  @override
  String toString() => 'HttpRequestException($message)';
}
