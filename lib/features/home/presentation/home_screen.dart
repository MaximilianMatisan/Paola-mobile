// Placeholder shown after login. Loads the current user from the web app to
// confirm the session works against the shared database.

import 'package:flutter/material.dart';

import 'package:interactive_notifications/core/network/paola_api.dart';
import 'package:interactive_notifications/core/style/paola_theme.dart';
import 'package:interactive_notifications/features/auth/presentation/login_page.dart';

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
      backgroundColor: PaolaColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: FutureBuilder<AppUser?>(
              future: _user,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator(
                    color: PaolaColors.primary,
                  );
                }
                final name = snap.data?.nickname;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientText(
                      name == null || name.isEmpty ? 'Hello!' : 'Hello, $name!',
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
                          style: TextStyle(color: PaolaColors.error),
                        ),
                      ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: _logout,
                      child: const Text(
                        'Log out',
                        style: TextStyle(color: PaolaColors.link),
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
