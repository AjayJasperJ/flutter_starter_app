import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

enum LogLevel { info, warning, error, debug }

class LoggerService {
  static File? _logFile;
  static final _lock = Lock();
  static final _logStream = StreamController<String>.broadcast();
  static Stream<String> get logStream => _logStream.stream;
  static const int _maxLogSize = 1024 * 1024 * 5;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File("${dir.path}/api_log.txt");
    if (!await _logFile!.exists()) {
      await _logFile!.create(recursive: true);
    }
    debugPrint("[LoggerService] Initialized at: ${_logFile!.path}");
  }

  static Future<void> _ensureInitialized() async {
    if (_logFile == null) {
      await init();
    }
  }

  static Future<void> log({
    required LogLevel level,
    required String category,
    required String message,
    Map<String, dynamic>? details,
  }) async {
    await _ensureInitialized();

    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name,
      'category': category,
      'message': message,
      if (details != null && details.isNotEmpty) 'details': details,
    };

    final jsonString = jsonEncode(entry, toEncodable: (o) => o.toString());
    await _writeLine(jsonString);
    _printToConsole(level, category, message, details);
  }

  static Future<void> logger(String message) async {
    await log(level: LogLevel.info, category: 'legacy', message: message);
  }

  static Future<void> logEvent({
    required String category,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    await log(
      level: LogLevel.info,
      category: category,
      message: action,
      details: details,
    );
  }

  static Future<void> logUi(
    String action, {
    Map<String, dynamic>? details,
  }) async {
    await logEvent(category: 'ui', action: action, details: details);
  }

  static Future<void> logApi(
    String endpoint, {
    required bool success,
    dynamic response,
    int? statusCode,
  }) async {
    await log(
      level: success ? LogLevel.info : LogLevel.error,
      category: 'api',
      message: '$endpoint | success: $success',
      details: {
        if (statusCode != null) 'statusCode': statusCode,
        if (response != null) 'response': response.toString(),
      },
    );
  }

  static Future<void> _writeLine(String line) async {
    await _lock.synchronized(() async {
      if (_logFile == null) return;

      if (await _logFile!.length() > _maxLogSize) {
        await _logFile!.writeAsString('', mode: FileMode.write);
        if (kDebugMode) {
          debugPrint("[LoggerService] Log file cleared (size > 5MB)");
        }
      }

      await _logFile!.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
      _logStream.add(line);
    });
  }

  static Future<void> overwriteLogs(List<String> logLines) async {
    await _lock.synchronized(() async {
      if (_logFile == null) await init();
      if (_logFile == null) return;

      final content = logLines.join('\n');
      await _logFile!.writeAsString(
        content.isEmpty ? '' : '$content\n',
        mode: FileMode.write,
        flush: true,
      );
    });
  }

  static void _printToConsole(
    LogLevel level,
    String category,
    String message,
    Map<String, dynamic>? details,
  ) {
    if (!kDebugMode) return;

    final color = level == LogLevel.error
        ? '\x1B[31m'
        : '\x1B[32m'; // Red or Green
    final reset = '\x1B[0m';
    final timestamp = DateTime.now()
        .toIso8601String()
        .split('T')[1]
        .substring(0, 8);

    debugPrint('$color[$timestamp][$category] $message$reset');
    if (details != null && details.isNotEmpty) {
      final prettyJson = const JsonEncoder.withIndent(
        '  ',
        _toEncodable,
      ).convert(details);
      debugPrint('$color$prettyJson$reset');
    }
  }

  static dynamic _toEncodable(dynamic o) => o.toString();

  static Future<String> readLogs() async {
    await _ensureInitialized();
    if (await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return "";
  }

  static void initGlobalErrorHandling() {
    // Capture Flutter framework errors (e.g. layout overflow)
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      log(
        level: LogLevel.error,
        category: 'flutter_error',
        message: details.exceptionAsString(),
        details: {
          'library': details.library,
          'context': details.context?.toString(),
          'stack': details.stack?.toString(),
          'summary': details.summary.toString(),
        },
      );
    };

    // Capture async Dart errors (e.g. Future exceptions)
    PlatformDispatcher.instance.onError = (error, stack) {
      log(
        level: LogLevel.error,
        category: 'app_error',
        message: error.toString(),
        details: {'stack': stack.toString()},
      );
      return true; // Prevent app crash
    };
  }

  static Future<void> clearLogs() async {
    await _ensureInitialized();
    if (await _logFile!.exists()) {
      await _logFile!.writeAsString('');
      if (kDebugMode) debugPrint("[LoggerService] Logs cleared");
    }
  }

  static Future<String> getLogPath() async {
    await _ensureInitialized();
    return _logFile?.path ?? "Log file not initialized";
  }
}
