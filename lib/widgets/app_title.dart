import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_text.dart';

class AppTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const AppTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final deviceTheme = Theme.of(context);
    return Column(
      children: [
        SizedBox(height: Dimen.h20),
        Txt(
          title,
          size: Dimen.s20,
          weight: Font.bold,
          color: deviceTheme.colorScheme.onSurface,
        ),
        if (subtitle != null)
          Txt(
            subtitle!,
            size: Dimen.s14,
            weight: Font.regular,
            color: deviceTheme.colorScheme.onSurface,
          ),
        SizedBox(height: Dimen.h20),
      ],
    );
  }
}
