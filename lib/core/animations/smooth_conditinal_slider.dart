import 'package:flutter/material.dart';

class SmoothConditionalSlide extends StatelessWidget {
  final bool visible;
  final Widget child;
  final double slideOffset;
  final Duration duration;
  final Curve curve;

  const SmoothConditionalSlide({
    super.key,
    required this.visible,
    required this.child,
    this.slideOffset = -0.25, 
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: duration,
      curve: curve,
      offset: visible ? Offset.zero : Offset(0, slideOffset),

      child: AnimatedOpacity(
        duration: duration, // SAME DURATION ✔
        curve: curve, // SAME CURVE ✔
        opacity: visible ? 1 : 0,

        child: AnimatedSize(
          duration: duration, // SAME DURATION ✔
          curve: curve,
          alignment: Alignment.topCenter,

          child: visible ? child : const SizedBox(height: 0, width: double.infinity),
        ),
      ),
    );
  }
}
