// Placeholder shown after login. Loads the current user from the web app to
// confirm the session works against the shared database.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';

import 'package:paola_mobile/core/network/paola_api.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/auth/presentation/login_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<AppUser?> _user = PaolaApi.instance.currentUser();

  Future<void> _logout() async {
    await PaolaApi.instance.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: FutureBuilder<AppUser?>(
              future: _user,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator(
                    color: context.colors.primary,
                  );
                }
                final name = snap.data?.nickname;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientText(
                      name == null || name.isEmpty
                          ? context.t.hello
                          : context.t.helloName(name),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (snap.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          snap.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: _logout,
                      child: Text(
                        context.t.logOut,
                        style: TextStyle(color: context.colors.link),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
