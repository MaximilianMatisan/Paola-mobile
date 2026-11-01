import 'package:flutter/material.dart';
import 'package:paola_mobile/features/study_history/presentation/history_screen.dart';
import 'package:paola_mobile/features/timer/presentation/timer_screen.dart';

import '../../features/settings/presentation/settings_screen.dart';
import 'bottom_bar.dart';

class MainEnvironment extends StatefulWidget {
  const MainEnvironment({super.key});

  @override
  State<MainEnvironment> createState() => _MainEnvironmentState();
}

class _MainEnvironmentState extends State<MainEnvironment> {
  // Opens on the timer.
  int _currentIndex = 0;

  static const _historyTab = 1;

  @override
  Widget build(BuildContext context) {
    // The home screen (features/home) is hidden for now; add it back here
    // and in CustomBottomNavigation to show it again.
    // IndexedStack keeps the timer running while another tab is open.
    final pages = [
      TimerScreen(
        onOpenHistory: () => setState(() => _currentIndex = _historyTab),
      ),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
