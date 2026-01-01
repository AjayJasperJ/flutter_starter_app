import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';
import '../../../core/config/keyboard_dismiss_observer.dart';
import '../../../core/config/overscroll_disable.dart';
import '../../../core/themes/theme.dart';
import '../../../core/utils/deeplink_services.dart';
import '../../../data/token_storage.dart';
import '../../../network/utils/connectivity_service.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/route_services.dart';
import '../../../dev_tools/widgets/dev_tools_overlay.dart';
import '../../../dev_tools/dev_tools_constants.dart';

class MyApp extends StatefulWidget {
  final bool enableScale;
  const MyApp({super.key, required this.enableScale});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late StreamSubscription _logoutSubscription;
  @override
  void initState() {
    super.initState();
    ConnectivityService().connectionChange.listen((isOnline) {
      if (isOnline) {
        // ToastType.internetConnected;
      } else {
        // ToastType.noInternet;
      }
    });
    _logoutSubscription = TokenStorage.logoutStream.listen((_) {
      debugPrint("[MyApp] Logout event received. Navigating to login...");
      RouteServices.removeUntil('/login', (route) => false);
    });
  }

  @override
  void dispose() {
    _logoutSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(402, 862),
      minTextAdapt: true,
      splitScreenMode: true,
      enableScaleText: () => widget.enableScale,
      enableScaleWH: () => widget.enableScale,
      builder: (context, child) => MaterialApp(
        scaffoldMessengerKey: _messengerKey,
        navigatorObservers: [KeyboardDismissObserver()],
        scrollBehavior: OverscrollDisable(),
        title: 'My App',
        themeAnimationCurve: Curves.easeInOut,
        navigatorKey: RouteServices.navigatorKey,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.test, //splash here
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        themeMode: ThemeMode.light,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        builder: (context, child) {
          final widget = ToastificationWrapper(child: child!);
          if (DevToolsConstants.kIncludeDevTools) {
            return DevToolsOverlay(child: widget);
          }
          return widget;
        },
      ),
    );
  }
}

class AppLifecycleHandler extends WidgetsBindingObserver {
  final DeepLinkService deepLinkService;
  AppLifecycleHandler(this.deepLinkService);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        deepLinkService.resetForWarmStart();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
