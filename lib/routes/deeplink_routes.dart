import 'package:flutter/material.dart';
import '../../../core/utils/deeplink_screen.dart';

class DeeplinkRoutes {
  static MaterialPageRoute<dynamic> routeTo(
    Widget Function(BuildContext context) target,
  ) => MaterialPageRoute(builder: target);

  static MaterialPageRoute buildRouteFromUri(Uri? uri) {
    if (uri == null) {
      return routeTo((context) => DeepLinkNotifier(message: 'Empty URI'));
    }
    final host = uri.host;
    // final segments = uri.pathSegments;

    // final id = segments.isNotEmpty ? segments.first : null;
    // final isDetail = host == "detail" && id != null;
    // final isTimesheet = host == "timesheet";
    // final isAi = host == "ai";

    return switch (host) {
      // "ai" => routeTo((context) => DeeplinkScreen(child: ChatbotScreen())),
      _ => routeTo(
        (context) =>
            DeeplinkScreen(child: DeepLinkNotifier(message: "Error 404")),
      ),
    };
  }
}
