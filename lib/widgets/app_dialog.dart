import 'package:flutter/material.dart';

/// Generic dialog that can return any type T
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required String label,
  required Widget Function(ValueNotifier<T?> valueNotifier) builder,
  EdgeInsets? innerPadding,
  EdgeInsets? outterPadding,
  BoxDecoration? decoration,
  double? height,
  double? width,
  Color? backgroundColor,
  T? initialValue,
}) {
  final valueNotifier = ValueNotifier<T?>(initialValue);

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: Colors.black.withValues(alpha: .5),
    transitionDuration: const Duration(milliseconds: 0),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          child: Container(
            decoration: decoration,
            height: height,
            width: width,
            margin: outterPadding,
            padding: innerPadding,
            color: backgroundColor,
            child: Material(
              type: MaterialType.card,
              color: Colors.transparent,
              child: builder(valueNotifier),
            ),
          ),
        ),
      );
    },
  );
}
