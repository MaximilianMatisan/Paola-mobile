import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
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

  static const _timerTab = 0;
  static const _historyTab = 1;

  final _timerKey = GlobalKey<TimerScreenState>();

  /// Switches the tab, warning first when that leaves a running timer
  Future<void> _openTab(int index) async {
    if (index == _currentIndex) return;
    final leavingTimer =
        _currentIndex == _timerTab &&
        index != _timerTab &&
        (_timerKey.currentState?.isRunning ?? false);
    if (leavingTimer) {
      final leave = await showDialog<bool>(
        context: context,
        barrierColor: context.colors.scrim,
        builder: (context) => const _LeaveTimerConfirmation(),
      );
      if (!mounted || leave != true) return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // The home screen (features/home) is hidden for now; add it back here
    // and in CustomBottomNavigation to show it again.
    // IndexedStack keeps the timer running while another tab is open.
    final pages = [
      TimerScreen(key: _timerKey, onOpenHistory: () => _openTab(_historyTab)),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _openTab,
      ),
    );
  }
}

class _LeaveTimerConfirmation extends StatelessWidget {
  const _LeaveTimerConfirmation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            type: MaterialType.transparency,
            child: PaolaCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.leaveTimerTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t.leaveTimerMessage,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: PaolaButton(
                          label: context.t.cancel,
                          style: PaolaButtonStyle.secondary,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PaolaButton(
                          label: context.t.leaveAnyway,
                          style: PaolaButtonStyle.primary,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
