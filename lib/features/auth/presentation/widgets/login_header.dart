import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';

import '../../util/auth_layout.dart';

class LoginHeader extends StatelessWidget {
  final String title;

  const LoginHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AuthLayout.titleFontSize,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      ),
    );
  }
}
