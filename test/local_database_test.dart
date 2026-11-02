import 'package:flutter_test/flutter_test.dart';
import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';
import 'package:paola_mobile/features/timer/models/mood.dart';
import 'package:paola_mobile/features/timer/models/study_activity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

FocusSession session(
  DateTime start, {
  int minutes = 25,
  bool pickedUp = false,
}) => FocusSession(
  start: start,
  pomodoro: true,
  periods: [
    FocusPeriod(
      start: start,
      end: start.add(Duration(minutes: minutes)),
      pickedUp: pickedUp,
    ),
  ],
);

void main() {
  final db = LocalDatabase.instance;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => db.init(path: inMemoryDatabasePath));
  tearDown(() => db.close());

  test('stores and reads back sessions, newest first', () async {
    final older = DateTime(2026, 11, 1, 9);
    final newer = DateTime(2026, 11, 2, 14);
    await db.saveSession(session(older, pickedUp: true));
    await db.saveSession(
      session(newer).withReflection([
        const ActivityReflection(
          activity: StudyActivity.exercises,
          rating: Mood.good,
          seconds: 600,
        ),
      ]),
    );

    final sessions = await db.sessions();
    expect(sessions.map((s) => s.start), [newer, older]);
    expect(sessions.last.periods.single.pickedUp, isTrue);
    expect(sessions.first.reflection!.single.activity, StudyActivity.exercises);
    expect(sessions.first.reflection!.single.seconds, 600);
    expect(sessions.first.reflection!.single.rating, Mood.good);
    expect(sessions.last.reflection, isNull);
  });

  test('saving the same start again replaces the session', () async {
    final start = DateTime(2026, 11, 2, 10);
    await db.saveSession(session(start, minutes: 10));
    await db.saveSession(session(start, minutes: 30));

    final sessions = await db.sessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.duration, const Duration(minutes: 30));
  });

  test('deleted sessions disappear', () async {
    final s = session(DateTime(2026, 11, 2, 10));
    await db.saveSession(s);
    await db.deleteSession(s);
    expect(await db.sessions(), isEmpty);
  });

  test('studyTimeOn sums the sessions of that day only', () async {
    await db.saveSession(session(DateTime(2026, 11, 1, 23, 50), minutes: 20));
    await db.saveSession(session(DateTime(2026, 11, 2, 8), minutes: 25));
    await db.saveSession(session(DateTime(2026, 11, 2, 15), minutes: 40));

    expect(
      await db.studyTimeOn(DateTime(2026, 11, 2, 12)),
      const Duration(minutes: 65),
    );
    expect(
      await db.studyTimeOn(DateTime(2026, 11, 1)),
      const Duration(minutes: 20),
    );
  });

  test('notifies listeners when sessions change', () async {
    var changes = 0;
    void listener() => changes++;
    db.sessionsChanged.addListener(listener);
    final s = session(DateTime(2026, 11, 2, 10));
    await db.saveSession(s);
    await db.deleteSession(s);
    db.sessionsChanged.removeListener(listener);
    expect(changes, 2);
  });
}
