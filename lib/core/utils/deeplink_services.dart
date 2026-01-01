import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../../data/token_storage.dart';
import '../../../routes/deeplink_routes.dart';
import '../../../routes/route_services.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  bool _isInitialized = false;
  bool _isColdStart = false;
  bool _hasProcessedColdStart = false;
  Uri? _initialColdStartUri;
  Uri? _pendingColdStartDeepLink;
  Completer<void>? _splashCompletionCompleter;
  Future<void> initDeepLinks({bool waitForSplashCompletion = false}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _isColdStart = true;
      _initialColdStartUri = initialUri;
      _pendingColdStartDeepLink = initialUri;
      if (waitForSplashCompletion) {
        _splashCompletionCompleter = Completer<void>();
      } else {
        _startLegacySplashTimer(() {
          _navigateFromColdStart(initialUri);
        });
      }
    } else {
      _isColdStart = true;
      _pendingColdStartDeepLink = null;
      if (waitForSplashCompletion) {
        _splashCompletionCompleter = Completer<void>();
      } else {
        _startLegacySplashTimer(() {
          _navigateFromColdStart(null);
        });
      }
    }
    _setupStreamListener();
  }

  void _startLegacySplashTimer(void Function() onComplete) {
    Timer(const Duration(seconds: 3), () {
      _hasProcessedColdStart = true;
      onComplete();
    });
  }

  void _setupStreamListener() {
    _subscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        final isDuplicateOfColdStart =
            _initialColdStartUri != null &&
            _initialColdStartUri.toString() == uri.toString();
        if (_isColdStart && !_hasProcessedColdStart && isDuplicateOfColdStart) {
          return;
        }
        if (TokenStorage.logged) {
          _handleWarmStartDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('[DeepLink] Stream error: $err');
      },
    );
  }

  void _handleWarmStartDeepLink(Uri uri) {
    final route = DeeplinkRoutes.buildRouteFromUri(uri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isNavigatorReady()) return;
      RouteServices.navigatorKey.currentState?.push(route);
    });
  }

  void _navigateFromColdStart(Uri? uri) {
    if (!_isNavigatorReady()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromColdStart(uri);
      });
      return;
    }
    final route = DeeplinkRoutes.buildRouteFromUri(uri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isNavigatorReady()) return;
      RouteServices.navigatorKey.currentState?.pushAndRemoveUntil(
        route,
        (Route<dynamic> route) => false,
      );
    });
  }

  Uri? getPendingDeepLink() {
    return _pendingColdStartDeepLink;
  }

  void splashCompleted() {
    _hasProcessedColdStart = true;
    if (_splashCompletionCompleter != null &&
        !_splashCompletionCompleter!.isCompleted) {
      _splashCompletionCompleter?.complete();
    }
    if (_pendingColdStartDeepLink != null) {
      _navigateFromColdStart(_pendingColdStartDeepLink);
    } else {
      _navigateFromColdStart(null);
    }
    _pendingColdStartDeepLink = null;
  }

  Future<void> waitForSplashCompletion() async {
    if (_splashCompletionCompleter != null) {
      await _splashCompletionCompleter!.future;
    }
  }

  void navigateFromSplash(Uri uri) {
    _hasProcessedColdStart = true;
    _pendingColdStartDeepLink = null;
    if (_splashCompletionCompleter != null &&
        !_splashCompletionCompleter!.isCompleted) {
      _splashCompletionCompleter?.complete();
    }
    _navigateFromColdStart(uri);
  }

  void resetForWarmStart() {
    _isColdStart = false;
    _hasProcessedColdStart = true;
    _initialColdStartUri = null;
    _pendingColdStartDeepLink = null;
  }

  bool _isNavigatorReady() {
    return RouteServices.navigatorKey.currentState != null &&
        RouteServices.navigatorKey.currentState!.mounted &&
        RouteServices.navigatorKey.currentContext != null &&
        RouteServices.navigatorKey.currentContext!.mounted;
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isColdStart': _isColdStart,
      'hasProcessedColdStart': _hasProcessedColdStart,
      'initialColdStartUri': _initialColdStartUri?.toString(),
      'pendingColdStartDeepLink': _pendingColdStartDeepLink?.toString(),
      'splashCompletionCompleter':
          _splashCompletionCompleter?.isCompleted ?? false,
      'streamSubscription': _subscription != null,
    };
  }

  void dispose() {
    _subscription?.cancel();
    if (_splashCompletionCompleter != null &&
        !_splashCompletionCompleter!.isCompleted) {
      _splashCompletionCompleter?.complete();
    }
  }
}
