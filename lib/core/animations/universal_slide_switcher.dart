import 'package:flutter/material.dart';

@immutable
class SlideFadeConfig {
  const SlideFadeConfig({
    this.duration = const Duration(milliseconds: 420),
    this.slideDistance = 0.22,
    this.enterSlideInterval = const Interval(0.55, 1.0),
    this.enterFadeInterval = const Interval(0.60, 1.0),
    this.exitFadeInterval = const Interval(0.0, 0.45),
    this.enterSlideCurve = Curves.easeOutCubic,
    this.enterFadeCurve = Curves.easeOut,
    this.exitFadeCurve = Curves.easeInCubic,
    this.useReducedMotion = false,
  });

  final Duration duration;
  final double slideDistance;
  final Interval enterSlideInterval;
  final Interval enterFadeInterval;
  final Interval exitFadeInterval;
  final Curve enterSlideCurve;
  final Curve enterFadeCurve;
  final Curve exitFadeCurve;
  final bool useReducedMotion;

  static const calendar = SlideFadeConfig();
  static const lowEnd = SlideFadeConfig(
    duration: Duration(milliseconds: 280),
    slideDistance: 0.12,
    enterSlideInterval: Interval(0.0, 1.0),
    enterFadeInterval: Interval(0.0, 1.0),
    exitFadeInterval: Interval(0.0, 1.0),
    enterSlideCurve: Curves.linear,
    enterFadeCurve: Curves.linear,
    exitFadeCurve: Curves.linear,
    useReducedMotion: true,
  );

  static SlideFadeConfig adaptive(BuildContext context) =>
      MediaQuery.of(context).disableAnimations ? lowEnd : calendar;

  SlideFadeConfig copyWith({
    Duration? duration,
    double? slideDistance,
    Interval? enterSlideInterval,
    Interval? enterFadeInterval,
    Interval? exitFadeInterval,
    Curve? enterSlideCurve,
    Curve? enterFadeCurve,
    Curve? exitFadeCurve,
    bool? useReducedMotion,
  }) {
    return SlideFadeConfig(
      duration: duration ?? this.duration,
      slideDistance: slideDistance ?? this.slideDistance,
      enterSlideInterval: enterSlideInterval ?? this.enterSlideInterval,
      enterFadeInterval: enterFadeInterval ?? this.enterFadeInterval,
      exitFadeInterval: exitFadeInterval ?? this.exitFadeInterval,
      enterSlideCurve: enterSlideCurve ?? this.enterSlideCurve,
      enterFadeCurve: enterFadeCurve ?? this.enterFadeCurve,
      exitFadeCurve: exitFadeCurve ?? this.exitFadeCurve,
      useReducedMotion: useReducedMotion ?? this.useReducedMotion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideFadeConfig &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          slideDistance == other.slideDistance &&
          enterSlideInterval == other.enterSlideInterval &&
          enterFadeInterval == other.enterFadeInterval &&
          exitFadeInterval == other.exitFadeInterval &&
          enterSlideCurve == other.enterSlideCurve &&
          enterFadeCurve == other.enterFadeCurve &&
          exitFadeCurve == other.exitFadeCurve &&
          useReducedMotion == other.useReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    duration,
    slideDistance,
    enterSlideInterval,
    enterFadeInterval,
    exitFadeInterval,
    enterSlideCurve,
    enterFadeCurve,
    exitFadeCurve,
    useReducedMotion,
  ]);
}

enum SlideDirection { left, right }

extension _SlideDirectionExt on SlideDirection {
  double get _sign => this == SlideDirection.right ? 1.0 : -1.0;
}

class UniversalSlideFadeSwitcher extends StatelessWidget {
  const UniversalSlideFadeSwitcher({
    super.key,
    required this.child,
    this.direction = SlideDirection.right,
    this.config = SlideFadeConfig.calendar,
  });

  final Widget child;
  final SlideDirection direction;
  final SlideFadeConfig config;

  @override
  Widget build(BuildContext context) {
    final effective = config.useReducedMotion
        ? SlideFadeConfig.lowEnd
        : SlideFadeConfig.adaptive(context);

    if (effective.useReducedMotion) return child;

    return AnimatedSwitcher(
      duration: effective.duration,
      switchInCurve: effective.enterSlideCurve,
      switchOutCurve: effective.exitFadeCurve,
      transitionBuilder: (child, animation) {
        final entering = animation.status != AnimationStatus.reverse;
        final dir = direction._sign;
        final dist = effective.slideDistance;

        if (entering) {
          final slide = CurvedAnimation(
            parent: animation,
            curve: Interval(
              effective.enterSlideInterval.begin,
              effective.enterSlideInterval.end,
              curve: effective.enterSlideCurve,
            ),
          );
          final fade = CurvedAnimation(
            parent: animation,
            curve: Interval(
              effective.enterFadeInterval.begin,
              effective.enterFadeInterval.end,
              curve: effective.enterFadeCurve,
            ),
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(dist * dir, 0),
                end: Offset.zero,
              ).animate(slide),
              child: child,
            ),
          );
        } else {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Interval(
              effective.exitFadeInterval.begin,
              effective.exitFadeInterval.end,
              curve: effective.exitFadeCurve,
            ),
          );
          return FadeTransition(opacity: fade, child: child);
        }
      },
      layoutBuilder: (currentChild, _) => currentChild ?? const SizedBox.shrink(),
      child: child,
    );
  }
}
