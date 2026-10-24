import 'package:flutter/material.dart';
import 'package:paola_mobile/core/navigation/main_environment.dart';
import 'package:paola_mobile/core/style/container.dart';
import 'package:paola_mobile/features/auth/data/auth_repository.dart';

import '../../../../core/style/text_field.dart';
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .start,
        children: [
          Spacer(),

          Container(
            decoration: defaultBoxDecoration(Theme.of(context).colorScheme.surfaceContainer),
            padding: const EdgeInsetsGeometry.all(25),

            child: Column(
              children: [
                LoginHeader(),

                const SizedBox(height: 70),

                TextFormField(
                  controller: _usernameController,
                  enabled: !_loginLoading,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: defaultTextInputBorder(),
                  ),
                  validator: (text) {
                    if (text == null || text.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_loginLoading,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: defaultTextInputBorder(),
                  ),
                  validator: (text) {
                    if (text == null || text.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                if (_loginErrorMsg != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _loginErrorMsg!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 5),
                ] else
                  const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loginLoading
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).primaryColor,
                      minimumSize: const Size(120, 55),
                    ),
                    onPressed: () async {
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
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MainEnvironment()),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        setState(() {
                          _loginErrorMsg = e.toString();
                          _loginLoading = false;
                        });
                      }
                    },
                    child: Text(
                      'LOG IN',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Spacer(),
          Center(
            child: TextButton(
              onPressed: () {
                if (_loginLoading) return;
                //TODO mail
              },
              child: const Text('Contact'),
            ),
          ),
          Center(child: ServerButton(enabled: !_loginLoading)),
        ],
      ),
    );
  }
}
