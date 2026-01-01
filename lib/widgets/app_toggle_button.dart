import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_multi_segment_troggle.dart';
import '../../../widgets/app_text.dart';

class TextToggle2Segment extends StatelessWidget {
  final int currentState;
  final ValueChanged<int> onChanged;
  final String label1;
  final String label2;

  const TextToggle2Segment({
    super.key,
    required this.currentState,
    required this.onChanged,
    required this.label1,
    required this.label2,
  });

  @override
  Widget build(BuildContext context) {
    final deviceTheme = Theme.of(context);
    return MultiSegmentToggle(
      height: Dimen.r45,
      segments: [
        Segment(
          builder: (color) =>
              Txt(label1, color: color, size: Dimen.s13, weight: Font.semibold),
        ),
        Segment(
          builder: (color) =>
              Txt(label2, color: color, size: Dimen.s13, weight: Font.semibold),
        ),
      ],
      activeColor: Colors.white,
      inactiveColor: deviceTheme.colorScheme.onSurface,
      indicatorColor: deviceTheme.colorScheme.onPrimaryContainer,
      backgroundColor: deviceTheme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(Dimen.r10),
      animationDuration: Duration(milliseconds: 350),
      indicatorBorderRadius: BorderRadius.circular(Dimen.r8),
      selectedIndex: currentState,
      onChanged: onChanged,
    );
  }
}

class IconToggle2Segment extends StatelessWidget {
  final int currentState;
  final ValueChanged<int> onChanged;
  final String iconpath1;
  final String iconpath2;

  const IconToggle2Segment({
    super.key,
    required this.currentState,
    required this.onChanged,
    required this.iconpath1,
    required this.iconpath2,
  });

  @override
  Widget build(BuildContext context) {
    final deviceTheme = Theme.of(context);
    return MultiSegmentToggle(
      height: Dimen.r45,
      segments: [
        Segment(
          builder: (color) => Image.asset(
            iconpath1,
            height: Dimen.r20,
            width: Dimen.r20,
            color: color,
          ),
        ),
        Segment(
          builder: (color) => Image.asset(
            iconpath2,
            height: Dimen.r20,
            width: Dimen.r20,
            color: color,
          ),
        ),
      ],
      activeColor: Colors.white,
      inactiveColor: deviceTheme.colorScheme.onSurface,
      animationDuration: Duration(milliseconds: 350),
      indicatorColor: deviceTheme.colorScheme.onPrimaryContainer,
      backgroundColor: deviceTheme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(Dimen.r10),
      indicatorBorderRadius: BorderRadius.circular(Dimen.r8),
      selectedIndex: currentState,
      onChanged: onChanged,
    );
  }
}
