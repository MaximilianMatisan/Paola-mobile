import 'package:flutter/material.dart';
import 'package:interactive_notifications/core/util/constants.dart';

class TimerButtons extends StatelessWidget {
  /// Timer has more >= 1 Seconds elapsed
  final bool isTimerSessionActive;
  final bool isTimerActive;
  final VoidCallback onPressedToggle;
  final VoidCallback onPressedReset;

  const TimerButtons({
    super.key,
    required this.isTimerSessionActive,
    required this.isTimerActive,
    required this.onPressedToggle,
    required this.onPressedReset,
  });

  @override
  Widget build(BuildContext context) {
    Color primaryCol = Theme.of(context).colorScheme.primary;
    Color onPrimaryCol = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisAlignment: .center,
      children: [
        Spacer(),
        _timerButton(
          onPressedToggle,
          isTimerActive ? 'PAUSE' : 'START',
          isTimerActive ? Icons.pause : Icons.play_arrow,
          onPrimaryCol,
          primaryCol,
        ),
        Spacer(),
        if (isTimerSessionActive) ...[
          _timerButton(
            onPressedReset,
            'STOP',
            Icons.stop,
            primaryCol,
            onPrimaryCol,
          ),
        Spacer(),
        ],
      ],
    );
  }

  Widget _timerButton(
    VoidCallback onPressed,
    String label,
    IconData icon,
    Color foregroundColor,
    Color backgroundColor,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: largeIconPixelSize),
      label: Text(label, style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(140, 58),
        elevation: 0,
      ),
    );
  }
}
