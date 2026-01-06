import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:convert';
import '../../data/token_storage.dart';
import '../../core/config/environment.dart';
import '../network_constants.dart'; // [NEW] Import NetworkConstants
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
import '../utils/network_utils.dart'; // [NEW] Import NetworkUtils

class ApiClient {
  late final Dio _dio;
  static final StreamController<String> _refreshController =
      StreamController<String>.broadcast();
  static Stream<String> get refreshStream => _refreshController.stream;
  // Box? _refreshBox; // [REMOVED] Persistent refresh queue
  static final Set<String> _recoveryQueue =
      {}; // [NEW] RAM-based recovery queue
  static final Set<String> _sessionFetchedKeys = {};
  static bool _isRecovering = false; // [NEW] Lock for auto-recovery
  final Map<String, (Future<ApiResult<Response>>, CancelToken?)>
  _inFlightRequests = {};
  ApiClient({String? baseUrl, Dio? dioOverride, Duration? timeout}) {
    final effectiveBaseUrl = _normalizeBase(baseUrl ?? Environment.apiUrl);
    debugPrint(
      '[ApiClient] Initializing with baseUrl: "$effectiveBaseUrl" (Source: ${baseUrl ?? 'Environment.apiUrl'})',
    );

    _dio =
        dioOverride ??
        Dio(
          BaseOptions(
            baseUrl: effectiveBaseUrl,
            connectTimeout:
                timeout ??
                const Duration(seconds: NetworkConstants.connectTimeoutSeconds),
            receiveTimeout:
                timeout ??
                const Duration(seconds: NetworkConstants.receiveTimeoutSeconds),
            sendTimeout:
                timeout ??
                const Duration(seconds: NetworkConstants.sendTimeoutSeconds),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );
    Box? cacheBox;
    Box? queueBox;
    if (Hive.isBoxOpen('api_cache')) cacheBox = Hive.box('api_cache');
    if (Hive.isBoxOpen('offline_queue')) queueBox = Hive.box('offline_queue');
    if (Hive.isBoxOpen('offline_queue')) queueBox = Hive.box('offline_queue');

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
        retries: NetworkConstants.maxRetries,
        retryDelays: NetworkConstants.retryDelaysSeconds
            .map((s) => Duration(seconds: s))
            .toList(),
        retryEvaluator: (error, attempt) {
          if (error.type == DioExceptionType.connectionError) {
            return false;
          }
          final retryableStatuses = {429};
          final retryableTypes = {
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
            DioExceptionType.unknown,
          };
          return retryableStatuses.contains(error.response?.statusCode) ||
              retryableTypes.contains(error.type);
        },
      ),
    );
    _dio.interceptors.add(PerformanceInterceptor());
    if (DevToolsConstants.kIncludeDevTools) {
      _dio.interceptors.add(ThrottlingInterceptor());
      _dio.interceptors.add(MockInterceptor());
    }
    _dio.interceptors.add(LoggerInterceptor());
    _dio.interceptors.add(AuthInterceptor(dio: _dio));
    ConnectivityService().connectionChange.listen((hasConnection) async {
      if (hasConnection) {
        await Future.delayed(const Duration(seconds: 2));
        await syncOfflineData();
        if (_recoveryQueue.isNotEmpty && !_isRecovering) {
          _isRecovering = true;
          debugPrint('[ApiClient] Starting RAM-Based Auto-Recovery Sync...');
          // Create a copy to iterate safely
          final keysToRefresh = _recoveryQueue.toList();

          for (final key in keysToRefresh) {
            if (_sessionFetchedKeys.contains(key)) {
              debugPrint(
                '[ApiClient] Skipping active screen (already fetched): $key',
              );
              _recoveryQueue.remove(key); // Cleanup
              continue;
            }
            final path = key;
            debugPrint('[ApiClient] Auto-Recovering (RAM): $path');

            await Future.delayed(const Duration(milliseconds: 300));
            final result = await get(
              path,
              withAuth: true,
              staleWhileRevalidate: false,
              sessionStale: false,
            );

            if (result.isSuccess) {
              _refreshController.add(path);
            }
          }
          debugPrint('[ApiClient] RAM Auto-Recovery Run Complete.');
          _isRecovering = false;
        }
      }
    });

    Future.microtask(() async {
      if (ConnectivityService().hasConnection) {
        await syncOfflineData();
      }
    });
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  static void resetSessionStale({String? path}) {
    if (path != null) {
      debugPrint('[NETWORK] Resetting session stale for path: $path');
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
    bool disableCache = false,
    bool disableLogger = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          extra: {
            'withAuth': withAuth,
            'disableCache': disableCache,
            'disableLogger': disableLogger,
          },
        ),
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
    bool staleWhileRevalidate = false,
    bool sessionStale = false,
    bool singleFetch = false,
    bool resetSingleFetch = false,
    bool resetCurrentStale = false,
    bool disableCache = false,
    bool disableLogger = false,
    Duration? cacheStorageDuration,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    String? queryString;
    if (query != null && query.isNotEmpty) {
      final sortedKeys = query.keys.toList()..sort();
      queryString = sortedKeys.map((k) => '$k=${query[k]}').join('&');
    }
    final requestKey = 'GET:$path${queryString != null ? '?$queryString' : ''}';
    if (_inFlightRequests.containsKey(requestKey)) {
      final entry = _inFlightRequests[requestKey]!;
      final existingCancelToken = entry.$2;

      // Smart Latest Wins: If new request has a DIFFERENT token, supersede the old one.
      // This ensures fresh interactions (which typically use a new CancelToken) don't
      // inherit a "dying" or "stale" future from a previous call.
      if (existingCancelToken != cancelToken) {
        debugPrint(
          '[NETWORK] Superseding in-flight request: $path (New Token Provided)',
        );
        existingCancelToken?.cancel("Superseded by newer request");
        _inFlightRequests.remove(requestKey);
      } else if (existingCancelToken == null ||
          !existingCancelToken.isCancelled) {
        debugPrint('[NETWORK] Deduplicating request: $path');
        return entry.$1;
      } else {
        debugPrint(
          '[NETWORK] Skipping deduplication for cancelled request: $path',
        );
        _inFlightRequests.remove(requestKey);
      }
    }
    if (resetCurrentStale) {
      debugPrint(
        '[NETWORK] ResetCurrentStale: Invalidating session cache for $path',
      );
      _sessionFetchedKeys.remove(requestKey);
    }

    // 1. Disable Cache Check
    if (!disableCache) {
      // 2. Session Stale (Memory)
      if (sessionStale && _sessionFetchedKeys.contains(requestKey)) {
        final cachedResponse = await _checkCache(path, query: query);
        if (cachedResponse != null) {
          debugPrint(
            '[NETWORK] SessionStale: Returning cached data for $path (Session Active)',
          );
          // Explicitly set isFromCache to false for session hits to avoid toast
          cachedResponse.extra['isFromCache'] = false;
          return ApiResult.success(cachedResponse);
        }
      }

      // 3. Single Fetch (Persistent)
      if (singleFetch && !resetSingleFetch) {
        final cachedResponse = await _checkCache(path, query: query);
        if (cachedResponse != null) {
          debugPrint(
            '[NETWORK] SingleFetch: Returning persistent cache for $path',
          );
          // Persistent hit -> isFromCache = true
          return ApiResult.success(cachedResponse);
        }
      }
    }

    final future = _getInternal(
      path,
      query: query,
      headers: headers,
      withAuth: withAuth,
      disableCache: disableCache,
      disableLogger: disableLogger,
      cacheStorageDuration: cacheStorageDuration,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );

    _inFlightRequests[requestKey] = (future, cancelToken);

    try {
      // 4. SWR (Persistent)
      // Only run SWR if cache is NOT disabled AND SWR is enabled
      final shouldServeSWR = !disableCache && staleWhileRevalidate;

      if (shouldServeSWR) {
        final cachedResponse = await _checkCache(path, query: query);
        if (cachedResponse != null) {
          debugPrint('[NETWORK] SWR: Returning cached data for $path');

          // Allow the background future to continue and clean up itself
          future.then((result) {
            if (result.isSuccess) {
              _sessionFetchedKeys.add(requestKey);
            }
            // Only remove if it's the SAME future
            if (_inFlightRequests[requestKey]?.$1 == future) {
              _inFlightRequests.remove(requestKey);
            }
          });

          return ApiResult.success(cachedResponse);
        }
      }

      final result = await future;

      // If network request was successful, mark this key as "fetched in session"
      // BUT only if it wasn't from cache (Offline Mode) to allow Auto-Recovery to run later.
      if (result.isSuccess) {
        final response =
            (result as dynamic).data as Response; // Dynamic cast to access data
        final isFromCache = response.extra['isFromCache'] ?? false;

        if (!isFromCache) {
          _sessionFetchedKeys.add(requestKey);
        }
      }

      return result;
    } finally {
      // Clean up in-flight mapping if we didn't return early
      if (_inFlightRequests.containsKey(requestKey)) {
        if (_inFlightRequests[requestKey]?.$1 == future) {
          _inFlightRequests.remove(requestKey);
        }
      }
    }
  }

  Future<Response?> _checkCache(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final cacheBox = Hive.isBoxOpen('api_cache') ? Hive.box('api_cache') : null;
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
      // Perform background parsing for consistency
      final data = cachedEntry['data'];
      // Use NetworkUtils to cast properly before parsing or returning
      final castData = NetworkUtils.castToMapStringDynamic(data);
      final decodedData = castData is String
          ? await compute(_parseJson, castData)
          : castData;

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
    bool disableCache = false,
    bool disableLogger = false,
    Duration? cacheStorageDuration,
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
          extra: {
            'withAuth': withAuth,
            'disableCache': disableCache,
            'disableLogger': disableLogger,
            if (cacheStorageDuration != null)
              'cacheStorageDuration': cacheStorageDuration,
          },
          responseType: ResponseType.plain,
        ),
      );

      final isFromCache = response.extra['isFromCache'] ?? false;

      // Reconstruct requestKey for consistency (identical to get() logic)
      // [REMOVED] queryString construction (Unused)
      // [REMOVED] requestKey (Unused)

      // [NEW] Simplified Recovery Key: Just the path (e.g. /teacher-timesheet)
      // This allows Providers to listen for general updates to this endpoint
      final recoveryKey = path;

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
        // [MODIFIED] RAM Registry: Record that this REQUEST needs a refresh when online
        if (!ConnectivityService().hasConnection) {
          if (!_recoveryQueue.contains(recoveryKey)) {
            debugPrint(
              '[ApiClient] Adding to RAM Recovery Queue: $recoveryKey',
            );
            _recoveryQueue.add(recoveryKey);
          }
        }
      } else {
        // [MODIFIED] Success from Network: Remove from recovery queue
        if (_recoveryQueue.contains(recoveryKey)) {
          debugPrint(
            '[ApiClient] Removing from RAM Recovery Queue (Success): $recoveryKey',
          );
          _recoveryQueue.remove(recoveryKey);
        }
        // [REMOVED] _refreshController.add(path); - Was causing infinite loop
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
    bool disableCache = false,
    bool disableLogger = false,
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
          extra: {
            'withAuth': withAuth,
            'isOfflineSync': isOfflineSync,
            'disableCache': disableCache,
            'disableLogger': disableLogger,
          },
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
    bool disableCache = false,
    bool disableLogger = false,
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
          extra: {
            'withAuth': withAuth,
            'isOfflineSync': isOfflineSync,
            'disableCache': disableCache,
            'disableLogger': disableLogger,
          },
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
    bool disableCache = false,
    bool disableLogger = false,
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
          extra: {
            'withAuth': withAuth,
            'isOfflineSync': isOfflineSync,
            'disableCache': disableCache,
            'disableLogger': disableLogger,
          },
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
    bool disableCache = false,
    bool disableLogger = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final formData = FormData();
      // ... (existing formData logic)
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
          extra: {
            'withAuth': withAuth,
            'disableCache': disableCache,
            'disableLogger': disableLogger,
          },
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
