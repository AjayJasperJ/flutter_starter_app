import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import '../../../widgets/app_text.dart';

class TextPill extends StatelessWidget {
  final Color color;
  final String text;
  final Color? textcolor;
  const TextPill({
    super.key,
    required this.color,
    required this.text,
    this.textcolor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Dimen.r99),
      ),
      padding: EdgeInsets.symmetric(horizontal: Dimen.w10, vertical: Dimen.h2),
      child: Txt(
        text,
        size: Dimen.s13,
        weight: Font.medium,
        color: textcolor ?? Colors.white,
      ),
    );
  }
}
