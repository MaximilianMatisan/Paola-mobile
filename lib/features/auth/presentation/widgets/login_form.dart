import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/auth/data/auth_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final label = TextStyle(fontSize: 13, color: context.colors.textSecondary);

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
                  const LoginHeader(),
                  const SizedBox(height: 25),

                  Text(t.loginUsername, style: label),
                  const SizedBox(height: 5),
                  _LoginField(
                    controller: _usernameController,
                    enabled: !_loginLoading,
                    textInputAction: TextInputAction.next,
                    validator: (text) => text == null || text.isEmpty
                        ? t.loginEnterUsername
                        : null,
                  ),
                  const SizedBox(height: 16),

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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _LoginField(
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
                    const SizedBox(height: 12),
                    Text(
                      _loginErrorMsg!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: PaolaButton(
                      label: t.loginButton,
                      onPressed: _loginLoading ? null : _login,
                    ),
                  ),

                  const Spacer(),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        if (_loginLoading) return;
                        //TODO mail
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.link,
                      ),
                      child: Text(t.loginContact),
                    ),
                  ),
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

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String> validator;

  const _LoginField({
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
      style: TextStyle(fontSize: 15, color: context.colors.textInput),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
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
