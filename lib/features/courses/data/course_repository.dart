// The user's courses and which one is selected, like CourseContext of the
// web app.
//
// Where courses come from:
//  * assets/db/init-courses.sql, the app's counterpart to the web app's
//    init-db.sql: the courses, their codes and sheets the app knows without
//    the web app. Read on every start. Without any course the user is in its
//    demo course, like after registering without a code on the web.
//  * The web app, when it is connected: its memberships, courses and sheets
//    replace the local ones on every fetch.
//
// Joining with a code goes to the web app if it is connected and reachable.
// Otherwise the code is looked up in init-courses.sql and the course joined
// on the device; the join is sent to the web app before the next fetch, and
// undone if the web app turns the code down.
//
// The selected course id is kept in shared preferences, like the web app
// keeps it in localStorage. If it is no longer one of the courses, the course
// joined first is selected.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/core/network/paola_api.dart';
import 'package:paola_mobile/features/courses/models/course.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a code did; [message] is the web app's reason if it turned the code
/// down.
typedef JoinResult = ({JoinOutcome outcome, Course? course, String? message});

class CourseRepository {
  CourseRepository._();
  static final CourseRepository instance = CourseRepository._();

  static const seedAsset = 'assets/db/init-courses.sql';
  static const _prefsSelected = 'selected_course_id';

  /// Answers of /api/course/join that mean the code itself is not valid.
  static const _codeRejected = {400, 404, 409};

  /// Courses, the one joined first first.
  final courses = ValueNotifier<List<Course>>(const []);

  /// Null if there are no courses.
  final selectedCourseId = ValueNotifier<int?>(null);

  /// Bumped when the web app session turned out to be of a user that no
  /// longer exists and was dropped.
  final sessionExpired = ValueNotifier(0);

  Course? get selectedCourse => _find(selectedCourseId.value);

  Course? _find(int? id) {
    for (final c in courses.value) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// [stored] if it is one of [courses], otherwise the first one.
  @visibleForTesting
  static int? pickSelection(List<Course> courses, int? stored) {
    if (stored != null && courses.any((c) => c.id == stored)) return stored;
    return courses.isEmpty ? null : courses.first.id;
  }

  /// Reads init-courses.sql ([seedSql] is for tests), then the stored
  /// courses and the saved selection.
  Future<void> init({String? seedSql}) async {
    final db = LocalDatabase.instance;
    await db.applySeed(seedSql ?? await rootBundle.loadString(seedAsset));
    if (!PaolaApi.instance.loggedIn) await db.ensureDemoMembership();
    await _reload();
  }

  Future<void> _reload() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await LocalDatabase.instance.courses();
    courses.value = list;
    final selected = pickSelection(list, prefs.getInt(_prefsSelected));
    selectedCourseId.value = selected;
    if (selected != null) await prefs.setInt(_prefsSelected, selected);
  }

  Future<void> select(int courseId) async {
    if (!courses.value.any((c) => c.id == courseId)) return;
    selectedCourseId.value = courseId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsSelected, courseId);
  }

  /// Joins the course of [code] and selects it.
  Future<JoinResult> join(String code) async {
    code = code.trim();
    final api = PaolaApi.instance;
    if (api.loggedIn) {
      try {
        if (!await api.sessionValid()) {
          await api.logout();
          sessionExpired.value++;
          throw const ApiException(message: 'session expired');
        }
        final r = await api.joinCourse(code);
        await refresh();
        await select(r.courseId);
        return (
          outcome: r.roleUpdated
              ? JoinOutcome.roleUpdated
              : r.alreadyMember
              ? JoinOutcome.alreadyMember
              : JoinOutcome.joined,
          course: _find(r.courseId),
          message: null,
        );
      } on ApiException catch (e) {
        if (_codeRejected.contains(e.statusCode)) {
          return (
            outcome: JoinOutcome.notFound,
            course: null,
            message: e.message,
          );
        }
        debugPrint('Joining on the web app failed, joining here: $e');
      } catch (e) {
        debugPrint('Web app not reachable, joining here: $e');
      }
    }
    final r = await LocalDatabase.instance.joinWithCode(code);
    await _reload();
    if (r.courseId != null && _find(r.courseId) != null) {
      await select(r.courseId!);
    }
    return (outcome: r.outcome, course: _find(r.courseId), message: null);
  }

  Future<List<String>>? _refreshing;

  /// Sends the courses joined on the device to the web app, then fetches
  /// the courses and their sheets and replaces the stored ones. Returns the
  /// web app's reasons for codes it turned down (those courses are left).
  /// Does nothing without a connection; if the web app can't be reached the
  /// stored ones stay. Calls while a fetch runs share it.
  Future<List<String>> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<List<String>> _refresh() async {
    final api = PaolaApi.instance;
    final db = LocalDatabase.instance;
    if (!api.loggedIn) return const [];
    final rejected = <String>[];
    try {
      // A session of a user the web app no longer has: log out, so the
      // settings ask for a new login. Pending joins wait for it.
      if (!await api.sessionValid()) {
        await api.logout();
        sessionExpired.value++;
        return const [];
      }
      for (final join in await db.pendingJoins()) {
        try {
          await api.joinCourse(join.code);
        } on ApiException catch (e) {
          if (!_codeRejected.contains(e.statusCode)) rethrow;
          await db.dropMembership(join.courseId);
          rejected.add('${join.code}: ${e.message}');
        }
      }

      final courseRows = await api.courses();
      final sheets = <Map<String, dynamic>>[];
      final exercises = <Map<String, dynamic>>[];
      for (final c in courseRows) {
        for (final s in await api.sheetsOf((c['id'] as num).toInt())) {
          sheets.add(s);
          exercises.addAll(await api.exercisesOf((s['id'] as num).toInt()));
        }
      }
      await db.replaceServerData(
        courses: courseRows,
        sheets: sheets,
        exercises: exercises,
      );
    } catch (e) {
      debugPrint('Loading courses failed, using saved ones: $e');
    }
    await _reload();
    return rejected;
  }
}
