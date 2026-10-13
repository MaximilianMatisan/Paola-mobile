
import 'package:flutter/material.dart';

import '../../util/format_time.dart';

class TimerDisplay extends StatelessWidget {
  final int secondsPassed;
  const TimerDisplay({super.key, required this.secondsPassed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        const Text('Time passed'),
        Text(
          formatTime(secondsPassed),
          style: Theme.of(context).textTheme.headlineMedium,
        )
    ]);
  }
}