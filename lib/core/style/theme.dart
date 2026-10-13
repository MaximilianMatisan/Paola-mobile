import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF27C85A),
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    ).copyWith(
      primary: const Color(0xFF34C759),
      onPrimary: Colors.white,
      secondary: const Color(0xFF00FF40),
      surface: const Color(0xFFFFFBF3),
      surfaceContainer: const Color(0xFFF6F2EA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFFCF6),
    );
  }
}
