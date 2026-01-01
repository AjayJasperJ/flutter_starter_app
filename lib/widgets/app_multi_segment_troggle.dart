import 'package:flutter/material.dart';

class Segment {
  final Widget Function(Color color) builder;
  const Segment({required this.builder});
}

/// MultiSegmentToggle using ValueNotifier instead of setState
class MultiSegmentToggle extends StatefulWidget {
  final List<Segment> segments;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  final Color backgroundColor;
  final Color indicatorColor;
  final Color activeColor;
  final Color inactiveColor;

  final double height;
  final double indicatorPadding;
  final Duration animationDuration;

  /// NEW: Customizable outer radius
  final BorderRadius? borderRadius;

  /// NEW: Customizable indicator radius
  final BorderRadius? indicatorBorderRadius;

  const MultiSegmentToggle({
    super.key,
    required this.segments,
    required this.selectedIndex,
    this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.indicatorColor = Colors.white,
    this.height = 48.0,
    this.indicatorPadding = 4.0,
    this.animationDuration = const Duration(milliseconds: 280),
    this.borderRadius,
    this.indicatorBorderRadius,
  }) : assert(segments.length > 1);

  @override
  State<MultiSegmentToggle> createState() => _MultiSegmentToggleState();
}

class _MultiSegmentToggleState extends State<MultiSegmentToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Replaces setState for progress rebuilds
  late ValueNotifier<double> _progressNotifier;

  @override
  void initState() {
    super.initState();

    _progressNotifier = ValueNotifier<double>(widget.selectedIndex.toDouble());

    _controller = AnimationController(duration: widget.animationDuration, vsync: this);

    _animation = Tween<double>(
      begin: _progressNotifier.value,
      end: _progressNotifier.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    /// update notifier as the animation runs
    _controller.addListener(() {
      _progressNotifier.value = _animation.value;
    });
  }

  @override
  void didUpdateWidget(covariant MultiSegmentToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateTo(widget.selectedIndex.toDouble());
    }

    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
  }

  void _animateTo(double target) {
    _animation = Tween<double>(
      begin: _progressNotifier.value,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.segments.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double segmentWidth = width / count;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          /// TAP → Smooth animation
          onTapUp: (details) {
            final int tappedIndex = (details.localPosition.dx / segmentWidth).floor().clamp(
              0,
              count - 1,
            );

            if (tappedIndex != widget.selectedIndex) {
              widget.onChanged?.call(tappedIndex);
            }

            _animateTo(tappedIndex.toDouble());
          },

          /// DRAG → Follow finger
          onHorizontalDragUpdate: (details) {
            final delta = details.primaryDelta! / segmentWidth;
            final newValue = (_progressNotifier.value + delta).clamp(0.0, (count - 1).toDouble());

            _progressNotifier.value = newValue;
          },

          /// DRAG END → Snap to nearest
          onHorizontalDragEnd: (_) {
            final int nearest = _progressNotifier.value.round().clamp(0, count - 1);

            if (nearest != widget.selectedIndex) {
              widget.onChanged?.call(nearest);
            }

            _animateTo(nearest.toDouble());
          },

          child: ValueListenableBuilder<double>(
            valueListenable: _progressNotifier,
            builder: (context, progress, _) {
              return Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
                ),
                child: Stack(
                  children: [
                    // Floating Indicator
                    Positioned(
                      left: progress * segmentWidth + widget.indicatorPadding,
                      top: widget.indicatorPadding,
                      bottom: widget.indicatorPadding,
                      width: segmentWidth - widget.indicatorPadding * 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.indicatorColor,
                          borderRadius:
                              widget.indicatorBorderRadius ??
                              BorderRadius.circular(
                                (widget.height - widget.indicatorPadding * 2) / 2,
                              ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Labels
                    Row(
                      children: List.generate(count, (i) {
                        final double t = (progress - i).abs().clamp(0.0, 1.0);

                        final Color color = Color.lerp(
                          widget.activeColor,
                          widget.inactiveColor,
                          t,
                        )!;

                        return Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: widget.segments[i].builder(color),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
