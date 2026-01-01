import 'dart:async';
import 'package:flutter/material.dart';

class AnimationServiceController {
  _AnimationServiceState? _state;
  AnimationServiceController();

  bool get isAnimating => _state?._controller.isAnimating ?? false;
  bool get isCompleted => _state?._controller.isCompleted ?? false;
  bool get isDismissed => _state?._controller.isDismissed ?? false;
  double get value => _state?._controller.value ?? 0.0;

  void playForward() => _state?.playForward();
  void playReverse() => _state?.playReverse();
  void reset() => _state?.reset();
  void toggle() => _state?.toggle();
  void restart() => _state?.restart();
}

class AnimationService extends StatefulWidget {
  const AnimationService({
    super.key,
    required this.child,
    required this.duration,
    this.reverseDuration,
    this.curve = Curves.easeOut,
    this.reverseCurve,
    this.startAfter = 0,
    this.autoStart = true,
    this.repeat = false,
    this.onComplete,
    this.onReverseComplete,
    required this.builder,
    this.controller,
  });

  final Widget child;
  final int duration;
  final int? reverseDuration;
  final Curve curve;
  final Curve? reverseCurve;
  final int startAfter;
  final bool autoStart;
  final bool repeat;
  final VoidCallback? onComplete;
  final VoidCallback? onReverseComplete;

  final Widget Function(BuildContext, Widget, Animation<double>) builder;

  final AnimationServiceController? controller;

  factory AnimationService.slideFade({
    Key? key,
    required Widget child,
    required int duration,
    int? reverseDuration,
    Curve curve = Curves.easeOut,
    Curve? reverseCurve,
    int startAfter = 0,
    bool autoStart = true,
    bool repeat = false,
    Offset beginOffset = const Offset(0, 32),
    Offset endOffset = Offset.zero,
    VoidCallback? onComplete,
    VoidCallback? onReverseComplete,
    AnimationServiceController? controller,
  }) {
    return AnimationService(
      key: key,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      startAfter: startAfter,
      autoStart: autoStart,
      repeat: repeat,
      onComplete: onComplete,
      onReverseComplete: onReverseComplete,
      controller: controller,
      child: child,
      builder: (_, c, a) {
        final slide = Tween<Offset>(begin: beginOffset, end: endOffset).animate(a);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(a);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: c),
        );
      },
    );
  }

  factory AnimationService.scaleFade({
    Key? key,
    required Widget child,
    required int duration,
    double beginScale = 0.8,
    double endScale = 1.0,
    int? reverseDuration,
    Curve curve = Curves.easeOutBack,
    Curve? reverseCurve,
    int startAfter = 0,
    bool autoStart = true,
    bool repeat = false,
    VoidCallback? onComplete,
    VoidCallback? onReverseComplete,
    AnimationServiceController? controller,
  }) {
    return AnimationService(
      key: key,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      startAfter: startAfter,
      autoStart: autoStart,
      repeat: repeat,
      onComplete: onComplete,
      onReverseComplete: onReverseComplete,
      controller: controller,
      child: child,
      builder: (_, c, a) {
        final scale = Tween<double>(begin: beginScale, end: endScale).animate(a);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(a);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: c),
        );
      },
    );
  }

  factory AnimationService.custom({
    Key? key,
    required Widget child,
    required int duration,
    required Widget Function(BuildContext, Widget, Animation<double>) builder,
    int? reverseDuration,
    Curve curve = Curves.linear,
    Curve? reverseCurve,
    int startAfter = 0,
    bool autoStart = true,
    bool repeat = false,
    VoidCallback? onComplete,
    VoidCallback? onReverseComplete,
    AnimationServiceController? controller,
  }) {
    return AnimationService(
      key: key,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      reverseCurve: reverseCurve,
      startAfter: startAfter,
      autoStart: autoStart,
      repeat: repeat,
      onComplete: onComplete,
      onReverseComplete: onReverseComplete,
      controller: controller,
      builder: builder,
      child: child,
    );
  }

  @override
  State<AnimationService> createState() => _AnimationServiceState();
}

class _AnimationServiceState extends State<AnimationService> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationServiceController api;
  bool _forward = true;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
      reverseDuration: widget.reverseDuration != null
          ? Duration(milliseconds: widget.reverseDuration!)
          : null,
    );
    api = AnimationServiceController().._state = this;
    widget.controller?._state = this;
    if (widget.autoStart) _scheduleStart();
    _controller.addStatusListener(_onStatus);
  }
  void _scheduleStart() {
    _delayTimer?.cancel();
    if (widget.startAfter > 0) {
      _delayTimer = Timer(Duration(milliseconds: widget.startAfter), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && _forward) {
      widget.onComplete?.call();
      if (widget.repeat) {
        _forward = false;
        _controller.reverse();
      }
    } else if (s == AnimationStatus.dismissed && !_forward) {
      widget.onReverseComplete?.call();
      if (widget.repeat) {
        _forward = true;
        _controller.forward();
      }
    }
  }

  void playForward() {
    _forward = true;
    _controller.forward();
  }

  void playReverse() {
    _forward = false;
    _controller.reverse();
  }

  void reset() => _controller.reset();

  void toggle() => _controller.isCompleted ? playReverse() : playForward();

  void restart() {
    reset();
    _scheduleStart();
  }

  @override
  void didUpdateWidget(covariant AnimationService old) {
    super.didUpdateWidget(old);

    if (old.duration != widget.duration) {
      _controller.duration = Duration(milliseconds: widget.duration);
    }
    if (old.reverseDuration != widget.reverseDuration) {
      _controller.reverseDuration = widget.reverseDuration != null
          ? Duration(milliseconds: widget.reverseDuration!)
          : null;
    }
    if (!old.autoStart && widget.autoStart) _scheduleStart();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    widget.controller?._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve ?? widget.curve,
    );
    return widget.builder(context, widget.child, anim);
  }
}
