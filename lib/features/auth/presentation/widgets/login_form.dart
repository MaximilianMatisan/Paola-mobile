import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/auth/data/auth_repository.dart';

import 'package:paola_mobile/features/auth/presentation/register_page.dart';

import 'auth_field.dart';
import '../../util/auth_layout.dart';
import 'login_header.dart';
import 'server_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<StatefulWidget> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _authRepository = AuthRepository();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _loginErrorMsg;
  bool _loginLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loginLoading = true;
      _loginErrorMsg = null;
    });

    try {
      await _authRepository.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Back to the settings, which opened the login.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginErrorMsg = e.toString();
        _loginLoading = false;
      });
    }
  }

  Future<void> _register() async {
    final registered = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RegisterPage()));
    if (registered == true && mounted) Navigator.pop(context, true);
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
                  LoginHeader(title: t.loginWelcome),
                  const SizedBox(height: AuthLayout.sectionGap),

                  Text(t.loginUsername, style: label),
                  const SizedBox(height: AuthLayout.labelGap),
                  AuthField(
                    controller: _usernameController,
                    enabled: !_loginLoading,
                    textInputAction: TextInputAction.next,
                    validator: (text) => text == null || text.isEmpty
                        ? t.loginEnterUsername
                        : null,
                  ),
                  const SizedBox(height: AuthLayout.fieldGap),

                  Row(
                    children: [
                      Expanded(child: Text(t.loginPassword, style: label)),
                      GestureDetector(
                        onTap: () {
                          //TODO mail
                        },
                        child: Text(
                          t.loginForgotPassword,
                          style: TextStyle(
                            fontSize: AuthLayout.smallFontSize,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AuthLayout.labelGap),
                  AuthField(
                    controller: _passwordController,
                    enabled: !_loginLoading,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    validator: (text) => text == null || text.isEmpty
                        ? t.loginEnterPassword
                        : null,
                  ),

                  if (_loginErrorMsg != null) ...[
                    const SizedBox(height: AuthLayout.errorGap),
                    Text(
                      _loginErrorMsg!,
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
                      label: t.loginButton,
                      onPressed: _loginLoading ? null : _login,
                    ),
                  ),

                  const SizedBox(height: AuthLayout.dividerGap),
                  Row(
                    children: [
                      const Expanded(child: Hairline()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AuthLayout.dividerTextPadding,
                        ),
                        child: Text(
                          t.or,
                          style: TextStyle(
                            fontSize: AuthLayout.smallFontSize,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Hairline()),
                    ],
                  ),
                  const SizedBox(height: AuthLayout.dividerGap),

                  SizedBox(
                    width: double.infinity,
                    child: PaolaButton(
                      label: t.registerButton,
                      style: PaolaButtonStyle.secondary,
                      onPressed: _loginLoading ? null : _register,
                    ),
                  ),

                  const Spacer(),
                  Center(child: ServerButton(enabled: !_loginLoading)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
