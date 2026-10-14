import 'package:flutter/material.dart';
import 'package:interactive_notifications/features/home/presentation/home_page.dart';
import 'package:interactive_notifications/features/timer/presentation/timer_page.dart';

import '../../features/settings/presentation/settings_page.dart';
import 'bottom_bar.dart';

class MainEnvironment extends StatefulWidget {
  const MainEnvironment({super.key});

  @override
  State<MainEnvironment> createState() => _MainEnvironmentState();
}

class _MainEnvironmentState extends State<MainEnvironment> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomePage(), TimerPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
