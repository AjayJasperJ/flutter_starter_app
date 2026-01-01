import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../network/utils/logger_services.dart';

class NetworkController {
  NetworkController._internal();
  static final NetworkController _instance = NetworkController._internal();
  factory NetworkController() => _instance;

  final ValueNotifier<List<Map<String, dynamic>>> apiLogs = ValueNotifier([]);
  static const int _maxLogs = 200; // API logs are heavier, so limit to 200
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _throttle;

  void init() {
    _loadInitial();
    LoggerService.logStream.listen(_onNewLog);
  }

  Future<void> _loadInitial() async {
    final content = await LoggerService.readLogs();
    if (content.isEmpty) return;

    final allLogs = await compute(_parseApiLogs, content);
    apiLogs.value = allLogs;
  }

  void _onNewLog(String line) {
    try {
      final log = jsonDecode(line) as Map<String, dynamic>;
      if (log['category'] == 'api') {
        _buffer.add(log);
        _scheduleUpdate();
      }
    } catch (_) {}
  }

  void _scheduleUpdate() {
    if (_throttle?.isActive ?? false) return;
    _throttle = Timer(const Duration(milliseconds: 500), () {
      final newLogs = [...apiLogs.value, ..._buffer];
      if (newLogs.length > _maxLogs) {
        apiLogs.value = newLogs.sublist(newLogs.length - _maxLogs);
      } else {
        apiLogs.value = newLogs;
      }
      _buffer.clear();
    });
  }

  void clear() {
    apiLogs.value = [];
  }

  static List<Map<String, dynamic>> _parseApiLogs(String content) {
    final lines = content.trim().split('\n');
    return lines
        .map((line) {
          try {
            final log = jsonDecode(line) as Map<String, dynamic>;
            return log['category'] == 'api' ? log : null;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
