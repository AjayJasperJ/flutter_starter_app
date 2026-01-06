import 'package:flutter/material.dart';
import 'package:flutter_starter_app/core/toasts/toast_manager.dart';
import 'package:toastification/toastification.dart';

class NetworkUtils {
  static dynamic castToMapStringDynamic(dynamic data) {
    if (data is Map) {
      return data.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), castToMapStringDynamic(value)),
      );
    } else if (data is List) {
      return data.map((e) => castToMapStringDynamic(e)).toList();
    }
    return data;
  }

  static void notifyCacheUse(BuildContext context) {
    ToastManager.showToast(
      message: "You are viewing offline data",
      type: ToastificationType.warning,
    );
  }
}
