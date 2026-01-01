import 'package:flutter/material.dart';

class JumpToBottomFAB extends StatefulWidget {
  final ScrollController scrollController;
  final double visibilityThreshold;

  const JumpToBottomFAB({
    super.key,
    required this.scrollController,
    this.visibilityThreshold = 200,
  });

  @override
  State<JumpToBottomFAB> createState() => _JumpToBottomFABState();
}

class _JumpToBottomFABState extends State<JumpToBottomFAB> {
  ValueNotifier<bool> isVisible = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (!widget.scrollController.hasClients) return;

    final double maxScroll = widget.scrollController.position.maxScrollExtent;
    final double currentScroll = widget.scrollController.position.pixels;
    final double distanceFromBottom = maxScroll - currentScroll;

    final bool shouldBeVisible =
        distanceFromBottom > widget.visibilityThreshold;

    if (shouldBeVisible != isVisible.value) {
      isVisible.value = shouldBeVisible;
    }
  }

  void _jumpToBottom() {
    widget.scrollController.animateTo(
      widget.scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isVisible,
      builder: (context, value, child) {
        return AnimatedScale(
          scale: value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.small(
            heroTag: null,
            onPressed: _jumpToBottom,
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
        );
      },
    );
  }
}
