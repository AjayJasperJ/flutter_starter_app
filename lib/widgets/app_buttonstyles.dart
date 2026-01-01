import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';

class CustomButtonstyles {
  static ButtonStyle filled(BuildContext context) {
    return ButtonStyle(
      // splashFactory: InkSplash.splashFactory,
      elevation: WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(Dimen.r99),
        ),
      ),
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.primary,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2);
        }
        return null;
      }),
    );
  }

  static ButtonStyle boardered(BuildContext context) {
    return ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimen.r99),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.3,
          ),
        ),
      ),
      // splashFactory: InkSplash.splashFactory,
      elevation: WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return Theme.of(context).colorScheme.primary.withValues(alpha: .2);
        } else if (states.contains(WidgetState.hovered)) {
          return Theme.of(context).colorScheme.onPrimary.withValues(alpha: .0);
        }
        return null;
      }),
    );
  }
}
