import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/core/data/local_settings.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:paola_mobile/core/navigation/main_environment.dart';
import 'package:paola_mobile/core/network/paola_api.dart';
import 'package:paola_mobile/core/style/theme.dart';
import 'package:paola_mobile/features/timer/util/hide_time.dart';
import 'package:paola_mobile/core/util/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Errors while building a widget show their message instead of the plain
  // grey box of release builds.
  ErrorWidget.builder = (details) => Material(
    child: _ErrorText('Build error', details.exception, details.stack),
  );

  final steps = <String, Future<void> Function()>{
    'Loading .env': () => dotenv.load(fileName: ".env"),
    'Loading language': AppLanguage.init,
    'Opening database': LocalDatabase.instance.init,
    'Loading settings': LocalSettings.init,
    'Loading timer options': HideTime.init,
    'Restoring web app connection': PaolaApi.instance.init,
    'Setting up notifications': initNotifications,
  };
  for (final MapEntry(key: step, value: run) in steps.entries) {
    try {
      await run().timeout(const Duration(seconds: 10));
    } catch (e, stack) {
      runApp(
        MaterialApp(
          home: Scaffold(body: _ErrorText('Startup failed: $step', e, stack)),
        ),
      );
      return;
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppTheme.mode, AppLanguage.current]),
      builder: (context, _) => MaterialApp(
        title: 'Paola Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppTheme.mode.value,
        // Flutter's own texts (copy/paste menu, tooltips) follow the language.
        locale: Locale(AppLanguage.current.value.name),
        supportedLocales: [for (final l in Language.values) Locale(l.name)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => LanguageScope(child: child!),
        // Works on the local data; the web app is set up in the settings.
        home: const MainEnvironment(),
      ),
    );
  }
}

/// Scrollable, selectable error report.
class _ErrorText extends StatelessWidget {
  final String title;
  final Object error;
  final StackTrace? stack;

  const _ErrorText(this.title, this.error, this.stack);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          '$title\n\n$error\n\n$stack',
          style: const TextStyle(fontSize: 12, color: Colors.red),
        ),
      ),
    );
  }
}
