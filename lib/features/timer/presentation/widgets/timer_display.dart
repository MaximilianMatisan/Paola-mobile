
import 'package:flutter/material.dart';

import '../../util/format_time.dart';

class TimerTextDisplay extends StatelessWidget {
  final int secondsPassed;
  const TimerTextDisplay({super.key, required this.secondsPassed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        const Text('Time passed'),
        Text(
          formatTime(secondsPassed),
          style: TextStyle (
            fontWeight: FontWeight.bold,
            fontSize:40
          ),
        )
    ]);
  }
}