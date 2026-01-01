import 'package:flutter/material.dart';
import '../../../screens/test_screen.dart';

class AppRoutes {
  // static const String splash = '/';
  static const String test = '/test';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // splash: (context) => SplashScreen(),
      test: (context) => TestScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // case updatePassword:
      //   final args = settings.arguments as Map<String, dynamic>?;
      //   return MaterialPageRoute(
      //     builder: (_) => ChangePasswordScreen(
      //       password: args?['password'],
      //       usercredential: args?['usercredential'],
      //     ),
      //   );
      default:
        return null;
    }
  }
}
