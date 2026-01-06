import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MockRule {
  final String id;
  final String pathPattern; // Regex or exact path
  final String method; // GET, POST, etc.
  final int statusCode;
  final String responseBody;
  final String requestBodyPattern; // Optional body match
  final bool isEnabled;
  final bool useRegex;

  MockRule({
    required this.id,
    required this.pathPattern,
    required this.method,
    this.statusCode = 200,
    required this.responseBody,
    this.requestBodyPattern = '',
    this.isEnabled = true,
    this.useRegex = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pathPattern': pathPattern,
      'method': method,
      'statusCode': statusCode,
      'responseBody': responseBody,
      'requestBodyPattern': requestBodyPattern,
      'isEnabled': isEnabled,
      'useRegex': useRegex,
    };
  }

  factory MockRule.fromMap(Map<dynamic, dynamic> map) {
    return MockRule(
      id: map['id'] as String,
      pathPattern: map['pathPattern'] as String,
      method: map['method'] as String,
      statusCode: map['statusCode'] as int? ?? 200,
      responseBody: map['responseBody'] as String,
      requestBodyPattern: map['requestBodyPattern'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      useRegex: map['useRegex'] as bool? ?? false,
    );
  }

  MockRule copyWith({
    String? pathPattern,
    String? method,
    int? statusCode,
    String? responseBody,
    String? requestBodyPattern,
    bool? isEnabled,
    bool? useRegex,
  }) {
    return MockRule(
      id: id,
      pathPattern: pathPattern ?? this.pathPattern,
      method: method ?? this.method,
      statusCode: statusCode ?? this.statusCode,
      responseBody: responseBody ?? this.responseBody,
      requestBodyPattern: requestBodyPattern ?? this.requestBodyPattern,
      isEnabled: isEnabled ?? this.isEnabled,
      useRegex: useRegex ?? this.useRegex,
    );
  }
}

class MockController {
  MockController._internal();
  static final MockController _instance = MockController._internal();
  factory MockController() => _instance;

  static const String _boxName = 'devtools_mock_rules';
  final ValueNotifier<List<MockRule>> rules = ValueNotifier<List<MockRule>>([]);

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    final box = Hive.box(_boxName);
    final List<MockRule> loadedRules = [];

    for (var key in box.keys) {
      final data = box.get(key);
      if (data is Map) {
        loadedRules.add(MockRule.fromMap(data));
      }
    }

    rules.value = loadedRules;
    debugPrint('[MockController] Initialized with ${loadedRules.length} rules');
  }

  Future<void> addRule(MockRule rule) async {
    final box = Hive.box(_boxName);
    await box.put(rule.id, rule.toMap());
    rules.value = [...rules.value, rule];
  }

  Future<void> updateRule(MockRule rule) async {
    final box = Hive.box(_boxName);
    await box.put(rule.id, rule.toMap());

    final index = rules.value.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      final newRules = List<MockRule>.from(rules.value);
      newRules[index] = rule;
      rules.value = newRules;
    }
  }

  Future<void> deleteRule(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
    rules.value = rules.value.where((r) => r.id != id).toList();
  }

  Future<void> toggleRule(String id) async {
    final index = rules.value.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = rules.value[index];
      await updateRule(rule.copyWith(isEnabled: !rule.isEnabled));
    }
  }

  Future<void> clearRules() async {
    final box = Hive.box(_boxName);
    await box.clear();
    rules.value = [];
  }
}
