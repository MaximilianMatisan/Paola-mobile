import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:interactive_notifications/core/navigation/main_environment.dart';
import 'package:interactive_notifications/core/network/paola_api.dart';
import 'package:interactive_notifications/core/style/theme.dart';
import 'package:interactive_notifications/features/auth/presentation/login_page.dart';
import 'package:interactive_notifications/core/util/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await PaolaApi.instance.init();
  await initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paola Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: PaolaApi.instance.loggedIn
          ? const MainEnvironment()
          : const LoginPage(),
    );
  }
}

