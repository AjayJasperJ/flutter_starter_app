import 'package:flutter/widgets.dart';

class RouteServices {
  static Future<T?> removeUntil<T extends Object?>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.pushNamedAndRemoveUntil<T>(
        newRouteName,
        predicate,
        arguments: arguments,
      );
    }
    return Future.value(null);
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.pushNamed<T>(routeName, arguments: arguments);
    }
    return Future.value(null);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.pushReplacementNamed<T, TO>(
        routeName,
        result: result,
        arguments: arguments,
      );
    }
    return Future.value(null);
  }

  static void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState?.pop<T>(result);
  }

  static Future<T?> push<T extends Object?>(Route<T> route) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.push<T>(route);
    }
    return Future.value(null);
  }

  static Future<bool> maybePop<T extends Object?>([T? result]) {
    return navigatorKey.currentState?.maybePop<T>(result) ??
        Future.value(false);
  }

  static void popUntil(RoutePredicate predicate) {
    navigatorKey.currentState?.popUntil(predicate);
  }

  static Future<T?> pushWithTransition<T extends Object?>(
    Widget target, {
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    RouteTransitionsBuilder? transitionsBuilder,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.push<T>(
        PageRouteBuilder(
          transitionDuration:
              transitionDuration ?? const Duration(milliseconds: 300),
          reverseTransitionDuration:
              reverseTransitionDuration ?? const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => target,
          transitionsBuilder:
              transitionsBuilder ??
              (_, animation, _, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                  reverseCurve: Curves.easeOut,
                );
                return RepaintBoundary(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
        ),
      );
    }
    return Future.value(null);
  }
}
