// Profile and appearance, stored on the device. The language is kept by
// AppLanguage the same way.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class LocalSettings {
  static const _nicknameKey = 'nickname';
  static const _darkModeKey = 'dark_mode';

  static final nickname = ValueNotifier('');

  /// Restores the saved nickname and applies the saved dark mode; until the
  /// user picks one the app follows the system.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    nickname.value = prefs.getString(_nicknameKey) ?? '';
    if (prefs.getBool(_darkModeKey) case final dark?) _applyDarkMode(dark);
  }

  /// Whether the app is dark right now, also when it follows the system.
  static bool get darkMode => switch (AppTheme.mode.value) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  static Future<void> setNickname(String name) async {
    nickname.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, name);
  }

  static Future<void> setDarkMode(bool enabled) async {
    _applyDarkMode(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  static void _applyDarkMode(bool enabled) =>
      AppTheme.mode.value = enabled ? ThemeMode.dark : ThemeMode.light;
}
