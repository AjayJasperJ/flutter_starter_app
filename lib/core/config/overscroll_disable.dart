
import 'package:flutter/material.dart';

class OverscrollDisable extends MaterialScrollBehavior {
  const OverscrollDisable();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
