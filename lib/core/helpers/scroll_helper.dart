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
  // Smart scroll: Re-checks maxScrollExtent to handle lazy-loaded content (e.g. images)
  // Added MAX RETRIES to prevent infinite loops.
  static Future<void> smartScrollToBottom({
    required ScrollController controller,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeOut,
  }) async {
    if (!controller.hasClients) return;

    int retries = 0;
    const maxRetries = 5; // Safety limit

    while (retries < maxRetries) {
      if (!controller.hasClients) break;

      final currentExtent = controller.position.maxScrollExtent;
      final position = controller.position.pixels;

      // If we are already at bottom (within tolerance), stop.
      if (position >= currentExtent - 1.0) break;

      await controller.animateTo(
        currentExtent,
        duration: duration,
        curve: curve,
      );

      // Wait for layout to possibly settle (e.g. images expanding)
      await Future.delayed(const Duration(milliseconds: 150));
      retries++;
    }
  }

  static Future<void> waitForKeyboardOpen(BuildContext context) async {
    int attempts = 0;
    // Poll for 2 seconds max
    while (context.mounted && attempts < 20) {
      if (View.of(context).viewInsets.bottom > 0) return; // Keyboard is Open!
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  static Future<void> waitForKeyboardClose(BuildContext context) async {
    int attempts = 0;
    while (context.mounted && attempts < 20) {
      if (View.of(context).viewInsets.bottom == 0)
        return; // Keyboard is Closed!
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  static bool isKeyboardOpen(BuildContext context) {
    return View.of(context).viewInsets.bottom > 0;
  }
}
