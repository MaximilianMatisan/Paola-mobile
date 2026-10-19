import 'package:flutter/material.dart';
import 'package:interactive_notifications/features/home/presentation/home_screen.dart';
import 'package:interactive_notifications/features/study_history/presentation/history_screen.dart';
import 'package:interactive_notifications/features/timer/presentation/timer_screen.dart';

import '../../features/settings/presentation/settings_screen.dart';
import 'bottom_bar.dart';

class MainEnvironment extends StatefulWidget {
  const MainEnvironment({super.key});

  @override
  State<MainEnvironment> createState() => _MainEnvironmentState();
}

class _MainEnvironmentState extends State<MainEnvironment> {
  // Opens on the timer.
  int _currentIndex = 1;

  // The history has no tab; it is opened from below the timer and belongs to
  // the timer tab.
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      // IndexedStack keeps the timer running while the history is open.
      IndexedStack(
        index: _showHistory ? 1 : 0,
        children: [
          TimerScreen(onOpenHistory: () => setState(() => _showHistory = true)),
          HistoryScreen(onBack: () => setState(() => _showHistory = false)),
        ],
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _showHistory = false;
          });
        },
      ),
    );
  }
}
