import 'package:flutter/material.dart';
import 'package:paola_mobile/features/auth/presentation/widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  final String title = 'Login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    // Opened from the settings to connect the web app; pops with true once
    // logged in.
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsetsGeometry.all(15),
        child: LoginForm(),
      ),
    );
  }
}
