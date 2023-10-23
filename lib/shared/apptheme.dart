import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? colorScheme) {
    final scheme = colorScheme ??
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.yellowAccent,
        );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData darkTheme(ColorScheme? colorScheme) {
    final scheme = colorScheme ??
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.yellowAccent,
        );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
    );
  }
}
