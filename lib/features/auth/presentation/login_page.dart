import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/auth/presentation/widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Opened from the settings to connect the web app; pops with true once
    // logged in.
    return Scaffold(
      appBar: AppBar(backgroundColor: context.colors.background),
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LoginForm(),
        ),
      ),
    );
  }
}
