import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageController {
  StorageController._internal();
  static final StorageController _instance = StorageController._internal();
  factory StorageController() => _instance;

  final ValueNotifier<List<String>> boxes = ValueNotifier([
    'api_cache',
    'offline_queue',
  ]);
  final ValueNotifier<String> selectedBox = ValueNotifier('api_cache');

  // We can't use ValueNotifier for the whole box easily because it's too big,
  // but we can listen to Hive box changes.

  void setSelectedBox(String boxName) {
    selectedBox.value = boxName;
  }

  Future<void> clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    }
  }

  Future<void> deleteKey(String boxName, dynamic key) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).delete(key);
    }
  }
}
