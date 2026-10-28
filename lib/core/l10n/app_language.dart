// The language the app is shown in. Like the dark mode it is stored in the
// web app's preferences (flag `language`), so both apps use the same one.
// It is also saved on the device, so the login screen already uses it.

import 'package:flutter/widgets.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppLanguage {
  static const _prefsKey = 'app_language';

  static final current = ValueNotifier(Language.de);

  /// Texts of the current language, for code without a [BuildContext].
  /// Widgets use `context.t` instead, so they rebuild on a change.
  static Translations get t => current.value.translations;

  /// Restores the saved language; on first start the phone's language,
  /// German or else English.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final code =
        saved ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    current.value = Language.values.firstWhere(
      (l) => l.name == code,
      orElse: () => saved == null ? Language.en : Language.de,
    );
  }

  /// Switches the app to [language] and remembers it on the device.
  static Future<void> set(Language language) async {
    current.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  }
}

/// Placed above all screens (MaterialApp.builder); rebuilds every widget
/// that read `context.t` when [AppLanguage.current] changes.
class LanguageScope extends InheritedNotifier<ValueNotifier<Language>> {
  LanguageScope({super.key, required super.child})
    : super(notifier: AppLanguage.current);
}

extension TranslationsContext on BuildContext {
  /// Texts of the current language, e.g. `context.t.save`.
  Translations get t {
    dependOnInheritedWidgetOfExactType<LanguageScope>();
    return AppLanguage.t;
  }
}
