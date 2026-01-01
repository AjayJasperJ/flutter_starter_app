import 'package:flutter/material.dart';

class ScrollHelper {
  static Future<void> scrollToBottom({
    required ScrollController controller,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (!controller.hasClients) return;
    await WidgetsBinding.instance.endOfFrame;

    if (!controller.hasClients) return;

    await controller.animateTo(
      controller.position.maxScrollExtent,
      duration: duration,
      curve: curve,
    );
  }

  // Scroll to top
  static Future<void> scrollToTop({
    required ScrollController controller,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (!controller.hasClients) return;
    await controller.animateTo(
      controller.position.minScrollExtent,
      duration: duration,
      curve: curve,
    );
  }

  // BEST METHOD: Use Flutter's built-in ensureVisible (recommended!)
  static Future<void> ensureVisible(
    GlobalKey key, {
    double alignment = 0.0 + .015,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  // Instant jump (no animation)
  static void jumpToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.jumpTo(controller.position.maxScrollExtent);
    }
  }

  static void jumpToTop(ScrollController controller) {
    if (controller.hasClients) {
      controller.jumpTo(controller.position.minScrollExtent);
    }
  }

  // Smart scroll for chat: handles images loading, new messages, etc.
  static Future<void> smartScrollToBottom({
    required ScrollController controller,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeOut,
  }) async {
    if (!controller.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 100));
    var previousExtent = controller.position.maxScrollExtent;
    while (true) {
      final currentExtent = controller.position.maxScrollExtent;
      if (currentExtent <= previousExtent + 1.0) break;
      await controller.animateTo(
        currentExtent,
        duration: duration,
        curve: curve,
      );
      previousExtent = currentExtent;
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  static Future<void> waitForKeyboardOpen(BuildContext context) async {
    if (context.mounted) {
      final value = MediaQuery.of(context).viewInsets.bottom == 0;
      while (value) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  static Future<void> waitForKeyboardClose(BuildContext context) async {
    if (context.mounted) {
      final value = MediaQuery.of(context).viewInsets.bottom > 0;
      while (value) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  static bool isKeyboardOpen(BuildContext context) {
    return View.of(context).viewInsets.bottom > 0;
  }
}
