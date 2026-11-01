import 'package:paola_mobile/core/util/displayable.dart';

enum TimerMode implements Displayable{
  stopwatch,
  pomodoro,
  flowtime;

  @override
  String toDisplayableString() {
    switch (this) {
      case stopwatch:
        return "STOPWATCH";
      case pomodoro:
        return "POMODORO";
      case flowtime:
        return "FLOWTIME";
    }
  }
}
