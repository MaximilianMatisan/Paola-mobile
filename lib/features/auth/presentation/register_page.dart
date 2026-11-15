import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/auth/util/auth_layout.dart';
import 'package:paola_mobile/features/auth/presentation/widgets/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: context.colors.background),
      backgroundColor: context.colors.background,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AuthLayout.pagePadding),
          child: RegisterForm(),
        ),
      ),
    );
  }
}
