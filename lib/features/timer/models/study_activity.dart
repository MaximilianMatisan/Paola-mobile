import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:paola_mobile/features/timer/models/mood.dart';

/// What the user did during a study session, chosen in the reflection after
/// a pomodoro. [name] is what goes into focus_period.reflection.
/// [marked] activities get the small orange dot, as in the web app.
enum StudyActivity {
  prepareLecture,
  attendLecture,
  reviewLecture,
  exercises(marked: true),
  quizzes(marked: true),
  repeatSummarize(marked: true),
  peerExchange(marked: true),
  organize(marked: true),
  other(marked: true);

  final bool marked;

  const StudyActivity({this.marked = false});

  String label(Translations t) => switch (this) {
    prepareLecture => t.activityPrepareLecture,
    attendLecture => t.activityAttendLecture,
    reviewLecture => t.activityReviewLecture,
    exercises => t.activityExercises,
    quizzes => t.activityQuizzes,
    repeatSummarize => t.activityRepeatSummarize,
    peerExchange => t.activityPeerExchange,
    organize => t.activityOrganize,
    other => t.activityOther,
  };

  /// Key stored in the database, e.g. "prepare_lecture".
  String get key =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static StudyActivity? fromKey(String key) {
    for (final a in values) {
      if (a.key == key) return a;
    }
    return null;
  }
}

/// One activity of a session's reflection: how it went and how much of the
/// session's time it took.
class ActivityReflection {
  final StudyActivity activity;
  final Mood? rating;
  final int seconds;

  const ActivityReflection({
    required this.activity,
    required this.rating,
    required this.seconds,
  });

  Map<String, dynamic> toJson() => {
    'activity': activity.key,
    'rating': rating?.name,
    'seconds': seconds,
  };

  /// Null for activities this app version doesn't know.
  static ActivityReflection? fromJson(Map<String, dynamic> json) {
    final activity = StudyActivity.fromKey('${json['activity']}');
    if (activity == null) return null;
    return ActivityReflection(
      activity: activity,
      rating: Mood.values.asNameMap()[json['rating']],
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
    );
  }
}
