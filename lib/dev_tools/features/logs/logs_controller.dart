import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../network/utils/logger_services.dart';

class LogsController {
  LogsController._internal();
  static final LogsController _instance = LogsController._internal();
  factory LogsController() => _instance;

  final ValueNotifier<List<Map<String, dynamic>>> logs = ValueNotifier([]);
  static const int _maxLogs = 500;
  final ValueNotifier<bool> autoScroll = ValueNotifier(true);

  final List<Map<String, dynamic>> _logBuffer = [];
  Timer? _throttleTimer;

  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    _loadInitialLogs();
    LoggerService.logStream.listen(_onNewLog);
  }

  Future<void> _loadInitialLogs() async {
    final logContent = await LoggerService.readLogs();
    if (logContent.isEmpty) return;

    final parsedLogs = await compute(_parseLogs, logContent);
    logs.value = [...logs.value, ...parsedLogs];
  }

  void _onNewLog(String line) {
    try {
      final log = jsonDecode(line) as Map<String, dynamic>;
      _logBuffer.add(log);

      if (_throttleTimer?.isActive ?? false) return;

      _throttleTimer = Timer(const Duration(milliseconds: 500), () {
        if (_logBuffer.isNotEmpty) {
          final newLogs = [...logs.value, ..._logBuffer];
          if (newLogs.length > _maxLogs) {
            logs.value = newLogs.sublist(newLogs.length - _maxLogs);
          } else {
            logs.value = newLogs;
          }
          _logBuffer.clear();
        }
      });
    } catch (e) {
      // Ignore parse errors
    }
  }

  Future<void> clearLogs() async {
    await LoggerService.clearLogs();
    logs.value = [];
  }

  Future<void> deleteLog(Map<String, dynamic> logToDelete) async {
    final updatedLogs = List<Map<String, dynamic>>.from(logs.value);
    updatedLogs.remove(logToDelete);
    logs.value = updatedLogs;

    final List<String> logLines = updatedLogs
        .map((log) => jsonEncode(log))
        .toList();
    await LoggerService.overwriteLogs(logLines);
  }

  void toggleAutoScroll() {
    autoScroll.value = !autoScroll.value;
  }

  static List<Map<String, dynamic>> _parseLogs(String content) {
    final lines = content.trim().split('\n');
    return lines
        .map((line) {
          try {
            return jsonDecode(line) as Map<String, dynamic>;
          } catch (e) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
