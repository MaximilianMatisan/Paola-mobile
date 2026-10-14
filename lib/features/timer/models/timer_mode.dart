import 'package:interactive_notifications/core/util/displayable.dart';

enum TimerMode implements Displayable{
  stopwatch,
  pomodoro;

  @override
  String toDisplayableString() {
    switch (this) {
      case stopwatch:
        return "STOPWATCH";
      case pomodoro:
        return "POMODORO";
    }
  }
}
