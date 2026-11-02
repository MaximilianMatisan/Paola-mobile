// A recorded timer session, the same shape as the web app's focus_period
// table. Stored locally (core/data/local_database.dart) and later synced.

import 'package:paola_mobile/features/timer/models/study_activity.dart';

/// Part of a timer session in which the phone layed still or was picked up
class FocusPeriod {
  final DateTime start;
  final DateTime end;
  final bool pickedUp;

  FocusPeriod({required this.start, required this.end, required this.pickedUp});

  Duration get duration => end.difference(start);

  factory FocusPeriod.fromJson(Map<String, dynamic> json) => FocusPeriod(
    start: DateTime.fromMillisecondsSinceEpoch((json['start'] as num).toInt()),
    end: DateTime.fromMillisecondsSinceEpoch((json['end'] as num).toInt()),
    pickedUp: json['picked_up'] == true,
  );

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'picked_up': pickedUp,
  };
}

/// A recorded timer session. Gaps between the periods are pauses.
class FocusSession {
  final DateTime start;
  final bool pomodoro;
  final List<FocusPeriod> periods;

  /// What was done in the session; null if the user gave no reflection.
  final List<ActivityReflection>? reflection;

  FocusSession({
    required this.start,
    required this.pomodoro,
    required this.periods,
    this.reflection,
  });

  FocusSession withReflection(List<ActivityReflection>? reflection) =>
      FocusSession(
        start: start,
        pomodoro: pomodoro,
        periods: periods,
        reflection: reflection,
      );

  Duration get duration =>
      periods.fold(Duration.zero, (sum, p) => sum + p.duration);

  /// Body of the web app's /api/focus_period/create.
  Map<String, dynamic> toJson() => {
    'session_start': start.millisecondsSinceEpoch,
    'is_pomodoro': pomodoro,
    'periods': [for (final p in periods) p.toJson()],
    if (reflection case final reflection?)
      'reflection': [for (final r in reflection) r.toJson()],
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    start: DateTime.fromMillisecondsSinceEpoch(
      (json['session_start'] as num).toInt(),
    ),
    pomodoro: json['is_pomodoro'] == true,
    periods: [
      for (final p in json['periods'] as List)
        FocusPeriod.fromJson(p as Map<String, dynamic>),
    ],
    reflection: switch (json['reflection']) {
      final List list => [
        for (final r in list)
          ?ActivityReflection.fromJson(r as Map<String, dynamic>),
      ],
      _ => null,
    },
  );
}
