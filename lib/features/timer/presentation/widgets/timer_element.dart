import 'package:flutter/material.dart';
import 'package:interactive_notifications/features/timer/presentation/widgets/pill_toggle.dart';
import 'package:interactive_notifications/features/timer/presentation/widgets/progress_ring.dart';
import 'package:interactive_notifications/features/timer/presentation/widgets/timer_buttons.dart';

import '../../../../core/style/container.dart';
import '../../models/timer_mode.dart';

class TimerElement extends StatefulWidget {
  final int secondsPassed;
  final bool isPaused;
  final VoidCallback onPressedToggle;
  final VoidCallback onPressedReset;

  const TimerElement({
    super.key,
    required this.secondsPassed,
    required this.isPaused,
    required this.onPressedToggle,
    required this.onPressedReset,
  });

  @override
  State<TimerElement> createState() => _TimerElementState();
}

class _TimerElementState extends State<TimerElement> {
  final List<TimerMode> _timerModeOptions = [
    TimerMode.stopwatch,
    TimerMode.pomodoro,
  ];
  int _selectedTimerModeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: defaultBoxDecoration(
        Theme.of(context).colorScheme.surfaceContainer,
      ),
      padding: EdgeInsetsGeometry.all(20.0),
      child: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .center,
        mainAxisSize: .min,
        children: [
          PillToggle(
            options: _timerModeOptions,
            selectedIndex: _selectedTimerModeIndex,
            onChanged: ((int newSelectionIndex) {
              setState(() {
                _selectedTimerModeIndex = newSelectionIndex;
              });
            }),
            isAllowedToChangeOption: widget.secondsPassed == 0,
          ),

          Padding(
            padding: EdgeInsetsGeometry.all(20),
            child: ProgressRingWidget(secondsPassed: widget.secondsPassed),
          ),
          TimerButtons(
            isTimerSessionActive: widget.secondsPassed > 0,
            isTimerActive: !widget.isPaused,
            onPressedToggle: widget.onPressedToggle,
            onPressedReset: widget.onPressedReset,
          ),
        ],
      ),
    );
  }
}
