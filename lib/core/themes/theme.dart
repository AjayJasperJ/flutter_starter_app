import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(fontFamily: "DMSans", colorScheme: ColorScheme.light());
  }

  static ThemeData darkTheme() {
    return ThemeData(fontFamily: "DMSans", colorScheme: ColorScheme.dark());
  }

  static ThemeMode theme = ThemeMode.light;
}
