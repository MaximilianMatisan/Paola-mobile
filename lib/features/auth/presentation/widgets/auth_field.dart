import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';

import '../../util/auth_layout.dart';

/// Text field of the login and register forms.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String> validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.textInputAction,
    required this.validator,
    this.obscureText = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PaolaRadius.control),
      borderSide: BorderSide(color: color),
    );
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: context.colors.primary,
      style: TextStyle(
        fontSize: AuthLayout.inputFontSize,
        color: context.colors.textInput,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuthLayout.fieldPaddingHorizontal,
          vertical: AuthLayout.fieldPaddingVertical,
        ),
        enabledBorder: border(context.colors.line),
        disabledBorder: border(context.colors.line),
        focusedBorder: border(context.colors.primary),
        errorBorder: border(context.colors.error),
        focusedErrorBorder: border(context.colors.error),
      ),
    );
  }
}
