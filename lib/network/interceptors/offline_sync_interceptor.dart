import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../../core/utils/notification_service.dart';
import '../services/background_sync_service.dart';
import '../utils/logger_services.dart';

class OfflineSyncInterceptor extends Interceptor {
  final Dio dio;
  final Box _queueBox;
  bool _isSyncing = false;
  static final Lock _lock = Lock();

  OfflineSyncInterceptor({required this.dio, required Box queueBox})
    : _queueBox = queueBox {
    debugPrint('[SYNC] Created.');
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final bool isOfflineSync =
        err.requestOptions.extra['isOfflineSync'] ?? true;
    final bool isSyncRequest =
        err.requestOptions.extra['isSyncRequest'] ?? false;
    if (!isSyncRequest &&
        _isNetworkError(err) &&
        [
          'POST',
          'PUT',
          'DELETE',
          'PATCH',
        ].contains(err.requestOptions.method) &&
        isOfflineSync) {
      debugPrint(
        '[SYNC] Network error during mutation. Queuing request: ${err.requestOptions.uri}',
      );
      await _queueRequest(err.requestOptions);
      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: {'offline_queued': true, 'message': 'Request queued for sync'},
          statusCode: 200,
        ),
      );
    }
    super.onError(err, handler);
  }

  Future<void> _queueRequest(RequestOptions options) async {
    final task = {
      'path': options.path,
      'method': options.method,
      'data': options.data,
      'query': options.queryParameters,
      'headers': options.headers,
      'contentType': options.contentType,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final exists = _queueBox.values.any((existing) {
      if (existing is! Map) {
        return false;
      }
      return existing['path'] == task['path'] &&
          existing['method'] == task['method'] &&
          existing['data'].toString() == task['data'].toString() &&
          existing['query'].toString() == task['query'].toString();
    });
    if (!exists) {
      debugPrint('[SYNC] Queuing offline processed request: ${options.path}');
      await _queueBox.add(task);

      // [NEW] notify user immediately
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Offline Sync',
        body: 'Action saved offline. Will sync when online.',
      );

      BackgroundSyncService().scheduleSyncTask();
    } else {
      debugPrint('[SYNC] Duplicate request ignored: ${options.path}');
    }
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        (err.error.toString().toLowerCase().contains('socket'));
  }

  dynamic _castToMapStringDynamic(dynamic data) {
    if (data is Map) {
      return data.map<String, dynamic>(
        (key, value) =>
            MapEntry(key.toString(), _castToMapStringDynamic(value)),
      );
    } else if (data is List) {
      return data.map((e) => _castToMapStringDynamic(e)).toList();
    }
    return data;
  }

  Future<void> syncQueue() async {
    return _lock.synchronized(() async {
      if (_isSyncing || _queueBox.isEmpty) {
        return;
      }
      _isSyncing = true;

      debugPrint('[SYNC] Starting sync of ${_queueBox.length} items...');

      final keys = _queueBox.keys.toList();

      for (final key in keys) {
        final task = _queueBox.get(key);
        if (task == null) {
          continue;
        }

        try {
          debugPrint(
            '[SYNC-v2] Processing index: $key | ${task['method']} ${task['path']}',
          );

          String? contentType = task['contentType'];
          if (task['path'].contains('/student-attendance') &&
              task['method'] == 'DELETE' &&
              contentType == null) {
            debugPrint(
              '[SYNC-v2] Failsafe: Forcing form-urlencoded for attendance delete',
            );
            contentType = 'application/x-www-form-urlencoded';
          }

          debugPrint('[SYNC-v2] Content-Type: $contentType');
          debugPrint('[SYNC-v2] Raw Data Type: ${task['data']?.runtimeType}');
          final dynamic processedData = _castToMapStringDynamic(task['data']);
          debugPrint('[SYNC-v2] Final Body Data: $processedData');

          await dio.request(
            task['path'],
            data: processedData,
            queryParameters: Map<String, dynamic>.from(task['query'] ?? {}),
            options: Options(
              method: task['method'],
              headers: Map<String, dynamic>.from(task['headers'] ?? {}),
              contentType: contentType,
              extra: {'isSyncRequest': true},
            ),
          );

          await _queueBox.delete(key);
          debugPrint('[SYNC-v2] Item $key sync success (deleted from queue)');
          await LoggerService.log(
            level: LogLevel.info,
            category: 'background_sync',
            message: 'Synced successfully: ${task['method']} ${task['path']}',
            details: {
              'item_index': key,
              'method': task['method'],
              'path': task['path'],
            },
          );
        } catch (e) {
          debugPrint('[SYNC] Failed to sync item $key: $e');
          await LoggerService.log(
            level: LogLevel.error,
            category: 'background_sync',
            message: 'Sync failed: ${task['method']} ${task['path']}',
            details: {
              'item_index': key,
              'error': e.toString(),
              'path': task['path'],
              'method': task['method'],
            },
          );
          if (e is DioException && e.response != null) {
            final code = e.response!.statusCode ?? 0;
            if (code >= 400 && code < 500 && code != 408 && code != 429) {
              // Fatal client error, delete from queue to avoid loop
              await _queueBox.delete(key);
              await LoggerService.log(
                level: LogLevel.warning,
                category: 'background_sync',
                message:
                    'Fatal client error ($code). Removing item $key from queue.',
              );
            }
          }
        }
      }

      _isSyncing = false;
      debugPrint('[SYNC] Sync completed.');
    });
  }
}
