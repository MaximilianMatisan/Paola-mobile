import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';

/// Builds the light and dark [ThemeData] from [PaolaColors], so screens that
/// still read `Theme.of(context).colorScheme` follow the same colours.
class AppTheme {
  AppTheme._();

  /// Follows the system until the dark mode preference is known, then the
  /// settings toggle.
  static final mode = ValueNotifier(ThemeMode.system);

  static ThemeData get light => _build(PaolaColors.light, Brightness.light);
  static ThemeData get dark => _build(PaolaColors.dark, Brightness.dark);

  static ThemeData _build(PaolaColors colors, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
    ).copyWith(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      secondaryContainer: colors.primaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      surface: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.line,
      scrim: colors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'FiraSans',
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
    );
  }
}
