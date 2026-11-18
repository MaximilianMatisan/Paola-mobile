// Profile and appearance, stored on the device. The language is kept by
// AppLanguage the same way.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class LocalSettings {
  static const _nicknameKey = 'nickname';
  static const _themeModeKey = 'theme_mode';

  static final nickname = ValueNotifier('');

  /// Restores the saved nickname and applies the saved colour scheme; until
  /// the user picks one the app follows the system.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    nickname.value = prefs.getString(_nicknameKey) ?? '';
    final saved = prefs.getString(_themeModeKey);
    if (saved != null) {
      AppTheme.mode.value = ThemeMode.values.asNameMap()[saved] ?? .system;
    }
  }

  static Future<void> setNickname(String name) async {
    nickname.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, name);
  }

  /// Light, dark, or [ThemeMode.system] to follow the phone's colour scheme.
  static Future<void> setThemeMode(ThemeMode mode) async {
    AppTheme.mode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}
