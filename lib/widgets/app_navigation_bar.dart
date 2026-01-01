import 'dart:math' as math;
import 'package:flutter/material.dart';

class CurvedNavigationBarItem {
  const CurvedNavigationBarItem({
    this.key,
    this.icon,
    this.title,
    this.child,
    this.semanticsLabel,
  }) : assert(
         child != null || icon != null || title != null,
         'Provide at least icon, title, or child',
       );

  final Key? key;
  final Widget? icon;
  final String? title;
  final Widget? child;
  final String? semanticsLabel;

  Widget build(
    BuildContext context,
    bool isSelected,
    Color? activeColor,
    Color? inactiveColor,
    TextStyle? activeTextStyle,
    TextStyle? inactiveTextStyle,
    double iconSize,
  ) {
    if (child != null) return child!;

    final Color? color = isSelected ? activeColor : inactiveColor;
    final TextStyle defaultStyle =
        Theme.of(context).textTheme.labelMedium ??
        DefaultTextStyle.of(context).style;
    final TextStyle resolvedTextStyle =
        (isSelected ? activeTextStyle : inactiveTextStyle) ?? defaultStyle;

    final children = <Widget>[];

    if (icon != null) {
      children.add(
        IconTheme(
          data: IconThemeData(size: iconSize, color: color),
          child: icon!,
        ),
      );
    }

    if (title != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 4));
      }
      children.add(
        Text(
          title!,
          style: resolvedTextStyle.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          softWrap: false,
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    } else if (children.length == 1) {
      return children.first;
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }
  }
}

class CurvedNavigationBar extends StatefulWidget {
  const CurvedNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.backgroundColor,
    this.shadowColor,
    this.activeColor,
    this.inactiveColor,
    this.highlightColor,
    this.highlightOpacity = 0.14,
    this.containerRadius = 20,
    this.horizontalPadding = 12,
    this.verticalPadding = 10,
    this.notchDepth = 20,
    this.notchWidthFactor = 0.1,
    this.animationDuration = const Duration(milliseconds: 360),
    this.animationCurve = Curves.easeOutCubic,
    this.itemAnimationDuration = const Duration(milliseconds: 260),
    this.itemAnimationCurve = Curves.easeOutCubic,
    this.itemHeight = 70,
    this.focusedIconSize = 25,
    this.unfocusedIconSize = 25,
    this.focusedTopPadding = 10,
    this.unfocusedTopPadding = 12,
    this.boxShadow,
    this.activeTextStyle,
    this.inactiveTextStyle,
    this.enableHover = true,
  }) : assert(items.length >= 2, 'Provide at least two items'),
       assert(containerRadius >= 0, 'containerRadius must be non-negative'),
       assert(horizontalPadding >= 0, 'horizontalPadding must be non-negative'),
       assert(verticalPadding >= 0, 'verticalPadding must be non-negative'),
       assert(notchDepth >= 0, 'notchDepth must be non-negative'),
       assert(notchWidthFactor >= 0, 'notchWidthFactor must be non-negative'),
       assert(itemHeight > 0, 'itemHeight must be greater than zero'),
       assert(focusedIconSize > 0, 'focusedIconSize must be greater than zero'),
       assert(
         unfocusedIconSize > 0,
         'unfocusedIconSize must be greater than zero',
       ),
       assert(focusedTopPadding >= 0, 'focusedTopPadding must be non-negative'),
       assert(
         unfocusedTopPadding >= 0,
         'unfocusedTopPadding must be non-negative',
       ),
       assert(
         highlightOpacity >= 0 && highlightOpacity <= 1,
         'highlightOpacity must be between 0 and 1',
       );

  /// Whether to enable hover, splash, and highlight effects on nav items.
  final bool enableHover;

  final List<CurvedNavigationBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  final Color? backgroundColor;
  final Color? shadowColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? highlightColor;
  final double highlightOpacity;

  final double containerRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final double notchDepth;
  final double notchWidthFactor;

  final Duration animationDuration;
  final Curve animationCurve;
  final Duration itemAnimationDuration;
  final Curve itemAnimationCurve;

  final double itemHeight;
  final double focusedIconSize;
  final double unfocusedIconSize;
  final double focusedTopPadding;
  final double unfocusedTopPadding;

  final List<BoxShadow>? boxShadow;
  final TextStyle? activeTextStyle;
  final TextStyle? inactiveTextStyle;

  @override
  State<CurvedNavigationBar> createState() => _CurvedNavigationBarState();
}

class _CurvedNavigationBarState extends State<CurvedNavigationBar> {
  late double _animationStart;

  @override
  void initState() {
    super.initState();
    _animationStart = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant CurvedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animationStart = oldWidget.selectedIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = widget.backgroundColor ?? colorScheme.surface;
    final shadowColor =
        widget.shadowColor ?? Colors.black.withValues(alpha: 0.08);
    final activeColor = widget.activeColor ?? colorScheme.primary;
    final inactiveColor =
        widget.inactiveColor ?? colorScheme.onSurface.withValues(alpha: 0.6);
    final highlightColor =
        widget.highlightColor ??
        activeColor.withValues(alpha: widget.highlightOpacity);

    final safeHorizontalPadding = math.max(0.0, widget.horizontalPadding);
    final safeVerticalPadding = math.max(0.0, widget.verticalPadding);
    final safeNotchDepth = math.max(0.0, widget.notchDepth);
    final safeNotchWidthFactor = math.max(
      0.0,
      math.min(1.0, widget.notchWidthFactor),
    );

    final boxShadow =
        widget.boxShadow ??
        [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _animationStart,
        end: widget.selectedIndex.toDouble(),
      ),
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      builder: (context, animatedIndex, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.containerRadius),
            boxShadow: boxShadow,
          ),
          child: ClipPath(
            clipper: _NavBarClipper(
              itemCount: widget.items.length,
              selectedPosition: animatedIndex,
              cornerRadius: widget.containerRadius,
              notchDepth: safeNotchDepth,
              notchWidthFactor: safeNotchWidthFactor,
              horizontalPadding: safeHorizontalPadding,
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: backgroundColor,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: safeHorizontalPadding,
                  vertical: safeVerticalPadding,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: _NavBarItem(
                          isSelected: widget.selectedIndex == i,
                          onTap: () => widget.onItemSelected(i),
                          highlightColor: highlightColor,
                          focusedTopPadding: widget.focusedTopPadding,
                          unfocusedTopPadding: widget.unfocusedTopPadding,
                          animationDuration: widget.itemAnimationDuration,
                          animationCurve: widget.itemAnimationCurve,
                          itemHeight: widget.itemHeight,
                          semanticsLabel:
                              widget.items[i].semanticsLabel ??
                              widget.items[i].title,
                          enableHover: widget.enableHover,
                          child: widget.items[i].build(
                            context,
                            widget.selectedIndex == i,
                            activeColor,
                            inactiveColor,
                            widget.activeTextStyle,
                            widget.inactiveTextStyle,
                            widget.selectedIndex == i
                                ? widget.focusedIconSize
                                : widget.unfocusedIconSize,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      onEnd: () {
        _animationStart = widget.selectedIndex.toDouble();
      },
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.child,
    required this.isSelected,
    required this.onTap,
    required this.highlightColor,
    required this.focusedTopPadding,
    required this.unfocusedTopPadding,
    required this.animationDuration,
    required this.animationCurve,
    required this.itemHeight,
    this.semanticsLabel,
    this.enableHover = true,
  });
  final bool enableHover;

  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final Color highlightColor;
  final double focusedTopPadding;
  final double unfocusedTopPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final double itemHeight;
  final String? semanticsLabel;

  static const double _cornerRadius = 24;
  static const double _notchDepth = 20;

  @override
  Widget build(BuildContext context) {
    final content = child;
    final targetTopPadding = isSelected
        ? focusedTopPadding
        : unfocusedTopPadding;
    final double effectiveTopPadding = math.min(
      math.max(0.0, targetTopPadding),
      math.max(0.0, itemHeight - 4),
    );

    return Semantics(
      selected: isSelected,
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cornerRadius),
        splashFactory: enableHover ? null : NoSplash.splashFactory,
        hoverColor: enableHover ? null : Colors.transparent,
        highlightColor: enableHover ? null : Colors.transparent,
        focusColor: enableHover ? null : Colors.transparent,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,margin: EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: SizedBox(
            height: itemHeight,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: animationDuration,
                    switchInCurve: animationCurve,
                    switchOutCurve: Curves.easeInCubic,
                    child: isSelected
                        ? _SelectedItemBackground(
                            key: ValueKey(semanticsLabel),
                            color: highlightColor,
                            notchDepth: _notchDepth,
                            cornerRadius: _cornerRadius,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                AnimatedPadding(
                  duration: animationDuration,
                  curve: animationCurve,
                  padding: EdgeInsets.only(top: effectiveTopPadding, bottom: 4),
                  child: content,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarClipper extends CustomClipper<Path> {
  const _NavBarClipper({
    required this.itemCount,
    required this.selectedPosition,
    required this.cornerRadius,
    required this.notchDepth,
    required this.notchWidthFactor,
    required this.horizontalPadding,
  });

  final int itemCount;
  final double selectedPosition;
  final double cornerRadius;
  final double notchDepth;
  final double notchWidthFactor;
  final double horizontalPadding;

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final radius = math.min(math.max(0.0, cornerRadius), height / 2);
    final path = Path();

    if (itemCount <= 0) {
      path.addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
      );
      return path;
    }

    final safeHorizontalPadding = math.min(
      math.max(0.0, horizontalPadding),
      width / 2,
    );
    final innerLeft = safeHorizontalPadding;
    final innerRight = width - safeHorizontalPadding;
    final availableWidth = math.max(0.0, innerRight - innerLeft);
    final safeNotchDepth = math.max(0.0, notchDepth);
    final safeNotchWidthFactor = math.max(0.0, math.min(1.0, notchWidthFactor));
    final segmentWidth = itemCount > 0 ? availableWidth / itemCount : 0.0;
    final clampedPosition = selectedPosition.clamp(
      0.0,
      math.max(0.0, itemCount - 1.0),
    );

    final hasNotch =
        safeNotchDepth > 0 && safeNotchWidthFactor > 0 && segmentWidth > 0;

    double notchStart = 0.0;
    double notchEnd = 0.0;
    double notchPeak = 0.0;
    double controlOffset = 0.0;
    double notchBottom = 0.0;

    if (hasNotch) {
      final notchCenter = innerLeft + segmentWidth * (clampedPosition + 0.5);
      final desiredHalfWidth = (segmentWidth * safeNotchWidthFactor) / 2;
      final minEdge = math.max(radius, innerLeft);
      final maxEdge = math.min(width - radius, innerRight);

      notchStart = notchCenter - desiredHalfWidth;
      notchEnd = notchCenter + desiredHalfWidth;

      if (notchStart < minEdge) {
        final shift = minEdge - notchStart;
        notchStart = minEdge;
        notchEnd = math.min(maxEdge, notchEnd + shift);
      }

      if (notchEnd > maxEdge) {
        final shift = notchEnd - maxEdge;
        notchEnd = maxEdge;
        notchStart = math.max(minEdge, notchStart - shift);
      }

      final notchWidth = (notchEnd - notchStart).clamp(0.0, width);
      if (notchWidth <= 0) {
        notchStart = notchEnd = notchCenter;
      }

      final effectiveHalfWidth = notchWidth / 2;
      controlOffset = math.max(6.0, effectiveHalfWidth * 0.6);
      notchBottom = math.min(safeNotchDepth, height * 0.65);
      notchPeak = notchStart + (notchEnd - notchStart) / 2;
    }

    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    if (hasNotch && notchEnd > notchStart) {
      path.lineTo(notchStart, 0);
      path.cubicTo(
        notchStart + controlOffset,
        0,
        notchPeak - controlOffset,
        notchBottom,
        notchPeak,
        notchBottom,
      );
      path.cubicTo(
        notchPeak + controlOffset,
        notchBottom,
        notchEnd - controlOffset,
        0,
        notchEnd,
        0,
      );
    }

    path.lineTo(width - radius, 0);
    path.quadraticBezierTo(width, 0, width, radius);
    path.lineTo(width, height - radius);
    path.quadraticBezierTo(width, height, width - radius, height);
    path.lineTo(radius, height);
    path.quadraticBezierTo(0, height, 0, height - radius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _NavBarClipper oldClipper) {
    return oldClipper.itemCount != itemCount ||
        oldClipper.selectedPosition != selectedPosition ||
        oldClipper.cornerRadius != cornerRadius ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.notchWidthFactor != notchWidthFactor ||
        oldClipper.horizontalPadding != horizontalPadding;
  }
}

class _SelectedItemBackground extends StatelessWidget {
  const _SelectedItemBackground({
    super.key,
    required this.color,
    required this.notchDepth,
    required this.cornerRadius,
  });

  final Color color;
  final double notchDepth;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SelectedItemPainter(
        color: color,
        notchDepth: notchDepth,
        cornerRadius: cornerRadius,
      ),
    );
  }
}

class _SelectedItemPainter extends CustomPainter {
  const _SelectedItemPainter({
    required this.color,
    required this.notchDepth,
    required this.cornerRadius,
  });

  final Color color;
  final double notchDepth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final width = size.width;
    final height = size.height;
    final bottomRadius = math.min(cornerRadius, height / 2);
    final controlDepth = math.min(notchDepth * 2, height - bottomRadius);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width / 2, controlDepth, width, 0)
      ..lineTo(width, height - bottomRadius)
      ..quadraticBezierTo(width, height, width - bottomRadius, height)
      ..lineTo(bottomRadius, height)
      ..quadraticBezierTo(0, height, 0, height - bottomRadius)
      ..close();

    canvas.drawPath(path, paint);

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SelectedItemPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
