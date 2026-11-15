import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/auth/data/auth_repository.dart';

import 'auth_field.dart';
import '../../util/auth_layout.dart';
import 'login_header.dart';

/// Limits from /api/auth/register of the paola web app
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  static const _minUsername = 3;
  static const _maxUsername = 64;
  static const _minPassword = 6;

  final _formKey = GlobalKey<FormState>();

  final _authRepository = AuthRepository();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();
  final _codeController = TextEditingController();

  String? _errorMsg;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _repeatController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await _authRepository.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        code: _codeController.text,
      );
      if (!mounted) return;
      // Back to the login, which closes as well.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = TextStyle(
      fontSize: AuthLayout.smallFontSize,
      color: context.colors.textSecondary,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  LoginHeader(title: t.registerWelcome),
                  const SizedBox(height: AuthLayout.sectionGap),

                  Text(t.loginUsername, style: label),
                  const SizedBox(height: AuthLayout.labelGap),
                  AuthField(
                    controller: _usernameController,
                    enabled: !_loading,
                    textInputAction: TextInputAction.next,
                    validator: (text) {
                      final length = text?.trim().length ?? 0;
                      return length < _minUsername || length > _maxUsername
                          ? t.registerUsernameLength
                          : null;
                    },
                  ),
                  const SizedBox(height: AuthLayout.fieldGap),

                  Text(t.loginPassword, style: label),
                  const SizedBox(height: AuthLayout.labelGap),
                  AuthField(
                    controller: _passwordController,
                    enabled: !_loading,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (text) => (text?.length ?? 0) < _minPassword
                        ? t.registerPasswordLength
                        : null,
                  ),
                  const SizedBox(height: AuthLayout.fieldGap),

                  Text(t.registerPasswordRepeat, style: label),
                  const SizedBox(height: AuthLayout.labelGap),
                  AuthField(
                    controller: _repeatController,
                    enabled: !_loading,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (text) => text != _passwordController.text
                        ? t.registerPasswordMismatch
                        : null,
                  ),
                  const SizedBox(height: AuthLayout.fieldGap),

                  Text(t.registerCode, style: label),
                  const SizedBox(height: AuthLayout.labelGap),
                  AuthField(
                    controller: _codeController,
                    enabled: !_loading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                    validator: (_) => null,
                  ),
                  const SizedBox(height: AuthLayout.labelGap),
                  Text(t.registerCodeHint, style: label),

                  if (_errorMsg != null) ...[
                    const SizedBox(height: AuthLayout.errorGap),
                    Text(
                      _errorMsg!,
                      style: TextStyle(
                        fontSize: AuthLayout.smallFontSize,
                        color: context.colors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AuthLayout.sectionGap),

                  SizedBox(
                    width: double.infinity,
                    child: PaolaButton(
                      label: t.registerButton,
                      onPressed: _loading ? null : _register,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
