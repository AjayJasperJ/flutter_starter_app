import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_text.dart';
import 'package:toastification/toastification.dart';

class ToastManager {
  static ToastificationItem? _current;
  static void showSingle(
    BuildContext context, {
    required String title,
    ToastificationType type = ToastificationType.info,
    ToastificationStyle style = ToastificationStyle.flat,
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Alignment alignment,
      Widget child,
    )?
    animationBuilder,
    Color? textcolor,
    int duration = 2,
    Function(ToastificationItem)? onTap,
  }) {
    if (_current != null) {
      Toastification().dismiss(_current!, showRemoveAnimation: false);
      _current = null;
    } else {
      Toastification().dismissAll(delayForAnimation: false);
    }
    _current = Toastification().show(
      style: style,
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      animationBuilder: animationBuilder,
      dragToClose: true,
      dismissDirection: DismissDirection.up,
      title: Txt(
        title,
        color: textcolor ?? Theme.of(context).colorScheme.onSurface,
        weight: Font.medium,
        size: 16.sp,
      ),
      icon: Icon(Icons.info, color: Theme.of(context).colorScheme.onSurface),
      type: type,
      alignment: Alignment.topCenter,
      autoCloseDuration: Duration(seconds: duration),
      callbacks: ToastificationCallbacks(onTap: onTap),
    );
  }

  static void showSingleCustom({required Widget child}) {
    // Always dismiss existing toast first
    if (_current != null) {
      toastification.dismiss(_current!, showRemoveAnimation: false);
      _current = null;
    }

    _current = toastification.showCustom(
      alignment: Alignment.topCenter,
      dismissDirection: DismissDirection.up,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 1000),
      animationBuilder: (context, animation, alignment, toastChild) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: toastChild),
        );
      },
      builder: (context, holder) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Dimen.r99),
          child: Center(child: child),
        );
      },
    );
  }

  static void dismiss() {
    if (_current != null) {
      toastification.dismiss(_current!, showRemoveAnimation: false);
      _current = null;
    }
  }
}
