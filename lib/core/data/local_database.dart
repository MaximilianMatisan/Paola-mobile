// The app's own database (SQLite on the device). Every timer session is
// stored here first, so the app works without the web app and offline.
//
// Each row remembers whether the web app has it (`on_server`) and whether it
// has changes the web app doesn't know yet (`pending`). A deleted session the
// web app has is only marked (`deleted`) until the sync has removed it there
// too; sessions the web app never had are removed at once.
//
// focus_sessions mirrors the web app's focus_period table:
//   session_start  ms since epoch, identifies the session (also on the server)
//   is_pomodoro    0/1
//   periods        JSON list of {start, end, picked_up}
//   reflection     JSON list of {activity, rating, seconds} or NULL
//   on_server      0/1, the web app has (a version of) this session
//   pending        0/1, changed here and not yet sent to the web app
//   deleted        0/1, deleted here, still to be deleted on the web app
//   course_id      course selected when it was recorded, NULL = none; only
//                  on the device (focus_period has no course)
//
// course, course_activation_code, exercise_sheet and exercise have the web
// app's names and columns (see its init-db.sql), so rows can be copied from
// there into assets/db/init-courses.sql. Each row has a `source`:
//   'seed'    from init-courses.sql, read again on every start (applySeed)
//   'server'  from the web app, replaced on every fetch (replaceServerData)
// A server row wins over a seed row with the same id; the courses the web app
// returned show only its sheets.
//
// course_membership is the user's courses on this device:
//   course_id      PRIMARY KEY, one membership per course like on the web
//   role           student / tutor / prof / forsch
//   joined_at      ISO time, the course joined first is selected first
//   join_code      code it was joined with on the device, NULL from the server
//   pending        1 = joined on the device, still to be joined on the web app
// Once connected, the web app's memberships replace these (after the pending
// ones were sent). They stay after logging out, so courses can still be
// switched offline.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:paola_mobile/core/data/sql_seed.dart';
import 'package:paola_mobile/core/util/constants.dart';
import 'package:paola_mobile/features/courses/models/course.dart';
import 'package:paola_mobile/features/study_history/models/exercise_sheet.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _file = 'paola.db';
  static const _version = 1;
  static const _sessions = 'focus_sessions';

  static const _sessionsTable =
      '''
    CREATE TABLE $_sessions (
      session_start INTEGER PRIMARY KEY,
      is_pomodoro INTEGER NOT NULL,
      periods TEXT NOT NULL,
      reflection TEXT,
      had_aha_moment INTEGER NOT NULL DEFAULT 0,
      on_server INTEGER NOT NULL DEFAULT 0,
      pending INTEGER NOT NULL DEFAULT 1,
      deleted INTEGER NOT NULL DEFAULT 0,
      course_id INTEGER
    )
    ''';

  /// The tables with the web app's names and columns, filled from
  /// init-courses.sql and the web app. init-courses.sql runs against the
  /// same tables in a throwaway database first (applySeed).
  /// No foreign keys: INSERT OR REPLACE would delete the dependent rows.
  static const _courseTables = {
    'course': '''
    CREATE TABLE course (
      id INTEGER PRIMARY KEY,
      owner_id INTEGER,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      allow_inline_replies INTEGER NOT NULL DEFAULT 1,
      source TEXT NOT NULL DEFAULT 'seed'
    )
    ''',
    'course_activation_code': '''
    CREATE TABLE course_activation_code (
      id INTEGER PRIMARY KEY,
      course_id INTEGER NOT NULL,
      code TEXT NOT NULL UNIQUE,
      role TEXT NOT NULL DEFAULT 'student',
      is_active INTEGER NOT NULL DEFAULT 1,
      max_uses INTEGER,
      uses_count INTEGER NOT NULL DEFAULT 0,
      expires_at TEXT,
      created_at TEXT,
      source TEXT NOT NULL DEFAULT 'seed'
    )
    ''',
    'exercise_sheet': '''
    CREATE TABLE exercise_sheet (
      id INTEGER PRIMARY KEY,
      title TEXT NOT NULL,
      course_id INTEGER NOT NULL,
      valid_from TEXT,
      valid_until TEXT,
      pdf_path TEXT,
      created_at TEXT,
      source TEXT NOT NULL DEFAULT 'seed'
    )
    ''',
    'exercise': '''
    CREATE TABLE exercise (
      id INTEGER PRIMARY KEY,
      sheet_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      solution TEXT NOT NULL DEFAULT '',
      created_at TEXT,
      source TEXT NOT NULL DEFAULT 'seed'
    )
    ''',
  };

  static const _membershipTable = '''
    CREATE TABLE course_membership (
      course_id INTEGER PRIMARY KEY,
      role TEXT NOT NULL DEFAULT 'student',
      joined_at TEXT,
      join_code TEXT,
      pending INTEGER NOT NULL DEFAULT 0
    )
    ''';

  static final _schema = [
    _sessionsTable,
    ..._courseTables.values,
    _membershipTable,
  ];

  /// Columns the web app's rows may fill, per table.
  static const _columns = {
    'course': {
      'id',
      'owner_id',
      'title',
      'description',
      'allow_inline_replies',
    },
    'exercise_sheet': {
      'id',
      'title',
      'course_id',
      'valid_from',
      'valid_until',
      'pdf_path',
      'created_at',
    },
    'exercise': {
      'id',
      'sheet_id',
      'title',
      'description',
      'solution',
      'created_at',
    },
  };

  Database? _db;

  Database get _open {
    final db = _db;
    if (db == null) throw StateError('LocalDatabase.init() was not called');
    return db;
  }

  /// Bumped whenever sessions change, so the history can reload.
  final sessionsChanged = ValueNotifier(0);

  /// Opens (and on first start creates) the database. [path] is for tests,
  /// e.g. [inMemoryDatabasePath].
  Future<void> init({String? path}) async {
    if (_db != null) return;
    _db = await openDatabase(
      path ?? p.join(await getDatabasesPath(), _file),
      version: _version,
      onCreate: (db, _) async {
        for (final sql in _schema) {
          await db.execute(sql);
        }
      },
    );
  }

  /// Closes the database; for tests.
  @visibleForTesting
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Map<String, Object?> _toRow(FocusSession s) => {
    'session_start': s.start.millisecondsSinceEpoch,
    'is_pomodoro': s.pomodoro ? 1 : 0,
    'periods': jsonEncode([for (final p in s.periods) p.toJson()]),
    'reflection': switch (s.reflection) {
      final r? => jsonEncode([for (final a in r) a.toJson()]),
      null => null,
    },
    'had_aha_moment': s.hadAhaMoment ? 1 : 0,
    'course_id': s.courseId,
  };

  static FocusSession _fromRow(Map<String, Object?> row) =>
      FocusSession.fromJson({
        'session_start': row['session_start'],
        'is_pomodoro': row['is_pomodoro'] == 1,
        'periods': jsonDecode(row['periods'] as String),
        'reflection': switch (row['reflection']) {
          final String r => jsonDecode(r),
          _ => null,
        },
        'had_aha_moment': row['had_aha_moment'] == 1,
      }).inCourse(row['course_id'] as int?);

  /// Stores [session], replacing one with the same start, and marks it to be
  /// sent to the web app. A session without a course keeps the course the
  /// stored one has (e.g. when it comes back from the web app).
  Future<void> saveSession(FocusSession session) async {
    final row = _toRow(session);
    await _open.transaction((txn) async {
      final updated = await txn.update(
        _sessions,
        {...row, 'pending': 1, 'deleted': 0}
          ..removeWhere((k, v) => k == 'course_id' && v == null),
        where: 'session_start = ?',
        whereArgs: [row['session_start']],
      );
      if (updated == 0) await txn.insert(_sessions, row);
    });
    sessionsChanged.value++;
  }

  /// Recorded sessions that aren't deleted, newest first. With [courseId]
  /// only that course's sessions and those recorded without a course.
  Future<List<FocusSession>> sessions({int? courseId}) async {
    final rows = await _open.query(
      _sessions,
      where: courseId == null
          ? 'deleted = 0'
          : 'deleted = 0 AND (course_id = ? OR course_id IS NULL)',
      whereArgs: [?courseId],
      orderBy: 'session_start DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Removes [session]; if the web app has it, it is only marked so the sync
  /// can delete it there as well.
  Future<void> deleteSession(FocusSession session) async {
    final start = session.start.millisecondsSinceEpoch;
    await _open.transaction((txn) async {
      await txn.delete(
        _sessions,
        where: 'session_start = ? AND on_server = 0',
        whereArgs: [start],
      );
      await txn.update(
        _sessions,
        {'deleted': 1, 'pending': 1},
        where: 'session_start = ?',
        whereArgs: [start],
      );
    });
    sessionsChanged.value++;
  }

  /// Total study time of the sessions that started on [day] (local time).
  Future<Duration> studyTimeOn(DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final rows = await _open.query(
      _sessions,
      where: 'deleted = 0 AND session_start >= ? AND session_start < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return rows
        .map(_fromRow)
        .fold<Duration>(Duration.zero, (sum, s) => sum + s.duration);
  }

  // ---------- Courses ----------

  /// Rows of init-courses.sql per table, written again after every fetch.
  Map<String, List<Map<String, Object?>>> _seed = const {};

  /// Reads init-courses.sql ([sql]) and replaces the seed rows with its
  /// rows. Rows the web app sent stay and win over seed rows with the same
  /// id.
  ///
  /// The statements run unchanged in a throwaway in-memory database that
  /// has only the course tables, so they can't touch sessions or
  /// memberships; the rows are then copied over. Throws a [SeedException]
  /// naming the statement SQLite refused.
  Future<void> applySeed(String sql) async {
    final scratch = await openDatabase(
      inMemoryDatabasePath,
      singleInstance: false,
    );
    try {
      for (final create in _courseTables.values) {
        await scratch.execute(create);
      }
      final statements = splitSqlStatements(sql);
      for (final (i, statement) in statements.indexed) {
        try {
          await scratch.execute(statement);
        } on DatabaseException catch (e) {
          throw SeedException(i + 1, statement, e);
        }
      }
      _seed = {
        for (final table in _courseTables.keys)
          table: await scratch.query(table),
      };
    } finally {
      await scratch.close();
    }
    await _open.transaction(_writeSeed);
  }

  Future<void> _writeSeed(Transaction txn) async {
    final batch = txn.batch();
    for (final MapEntry(key: table, value: rows) in _seed.entries) {
      batch.delete(table, where: "source = 'seed'");
      for (final row in rows) {
        batch.insert(table, {
          ...row,
          'source': 'seed',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    await batch.commit(noResult: true);
  }

  /// [row] of the web app limited to the local columns of [table]; sqflite
  /// takes no bools.
  static Map<String, Object?> _serverRow(
    String table,
    Map<String, dynamic> row,
  ) => {
    for (final MapEntry(:key, :value) in row.entries)
      if (_columns[table]!.contains(key))
        key: switch (value) {
          final bool b => b ? 1 : 0,
          final num n => n,
          null => null,
          _ => '$value',
        },
    'source': 'server',
  };

  /// Stores what the web app sent: [courses] as /api/course/myCourses returns
  /// them (course columns plus role and joined_at), and their [sheets] and
  /// [exercises]. They replace the previous server rows and all memberships;
  /// the pending ones must have been sent before.
  Future<void> replaceServerData({
    required List<Map<String, dynamic>> courses,
    required List<Map<String, dynamic>> sheets,
    required List<Map<String, dynamic>> exercises,
  }) async {
    await _open.transaction((txn) async {
      for (final table in _columns.keys) {
        await txn.delete(table, where: "source = 'server'");
      }
      await txn.delete('course_membership');
      final batch = txn.batch();
      for (final c in courses) {
        batch.insert(
          'course',
          _serverRow('course', c),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        batch.insert('course_membership', {
          'course_id': (c['id'] as num).toInt(),
          'role': '${c['role'] ?? 'student'}',
          'joined_at': c['joined_at']?.toString(),
          'pending': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final s in sheets) {
        batch.insert(
          'exercise_sheet',
          _serverRow('exercise_sheet', s),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final e in exercises) {
        batch.insert(
          'exercise',
          _serverRow('exercise', e),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      // Seed rows a server row had replaced come back if it is gone now.
      await _writeSeed(txn);
    });
  }

  /// The user's courses, the one joined first first.
  Future<List<Course>> courses() async {
    final rows = await _open.rawQuery('''
      SELECT c.id, c.owner_id, c.title, c.description, m.role, m.joined_at
      FROM course_membership m JOIN course c ON c.id = m.course_id
      ORDER BY m.joined_at IS NULL, m.joined_at, c.id
    ''');
    return rows.map(Course.fromRow).toList();
  }

  /// Sheets of [courseId] with their tasks; for a course of the web app only
  /// its sheets, not those of init-courses.sql.
  Future<List<ExerciseSheet>> sheetsOf(int courseId) async {
    final sheets = await _open.rawQuery(
      '''
      SELECT s.* FROM exercise_sheet s JOIN course c ON c.id = s.course_id
      WHERE s.course_id = ? AND s.source = c.source
      ORDER BY s.id
      ''',
      [courseId],
    );
    if (sheets.isEmpty) return [];
    final ids = [for (final s in sheets) s['id'] as int];
    final tasks = await _open.query(
      'exercise',
      where: 'sheet_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
      orderBy: 'id',
    );
    return [
      for (final s in sheets)
        ExerciseSheet.fromJson({
          ...s,
          'tasks': [
            for (final t in tasks)
              if (t['sheet_id'] == s['id'] && t['source'] == s['source']) t,
          ],
        }),
    ];
  }

  /// Joins the course of [code] from init-courses.sql on the device, like
  /// /api/course/join of the web app: a code of another role changes the
  /// role, joining a real course leaves the demo course. The usage limit
  /// (max_uses) is only checked by the web app, when the join is sent there.
  Future<({JoinOutcome outcome, int? courseId})> joinWithCode(
    String code, {
    DateTime? now,
  }) async {
    return _open.transaction((txn) async {
      final rows = await txn.query(
        'course_activation_code',
        where: 'code = ?',
        whereArgs: [code],
      );
      if (rows.isEmpty) return (outcome: JoinOutcome.notFound, courseId: null);
      final c = rows.single;
      final courseId = c['course_id'] as int;
      if (c['is_active'] == 0) {
        return (outcome: JoinOutcome.inactive, courseId: courseId);
      }
      final expires = DateTime.tryParse('${c['expires_at'] ?? ''}');
      if (expires != null && expires.isBefore(now ?? DateTime.now())) {
        return (outcome: JoinOutcome.expired, courseId: courseId);
      }
      final course = await txn.query(
        'course',
        where: 'id = ?',
        whereArgs: [courseId],
      );
      if (course.isEmpty) {
        return (outcome: JoinOutcome.notFound, courseId: null);
      }

      final role = '${c['role']}';
      final existing = await txn.query(
        'course_membership',
        where: 'course_id = ?',
        whereArgs: [courseId],
      );
      if (existing.isNotEmpty) {
        if (existing.single['role'] == role) {
          return (outcome: JoinOutcome.alreadyMember, courseId: courseId);
        }
        await txn.update(
          'course_membership',
          {'role': role, 'join_code': code, 'pending': 1},
          where: 'course_id = ?',
          whereArgs: [courseId],
        );
        return (outcome: JoinOutcome.roleUpdated, courseId: courseId);
      }
      await txn.insert('course_membership', {
        'course_id': courseId,
        'role': role,
        'joined_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
        'join_code': code,
        'pending': 1,
      });
      if (courseId != demoCourseId) {
        await txn.delete(
          'course_membership',
          where: 'course_id = ? AND pending = 0',
          whereArgs: [demoCourseId],
        );
      }
      return (outcome: JoinOutcome.joined, courseId: courseId);
    });
  }

  /// Without any course, the demo course of init-courses.sql (if it has
  /// one), like registering without a code in the web app.
  Future<void> ensureDemoMembership() async {
    final any = await _open.query('course_membership', limit: 1);
    if (any.isNotEmpty) return;
    final demo = await _open.query(
      'course',
      where: 'id = ?',
      whereArgs: [demoCourseId],
    );
    if (demo.isEmpty) return;
    await _open.insert('course_membership', {
      'course_id': demoCourseId,
      'role': 'student',
      'pending': 0,
    });
  }

  /// Courses joined on the device that the web app doesn't know yet.
  Future<List<({int courseId, String code})>> pendingJoins() async {
    final rows = await _open.query(
      'course_membership',
      where: 'pending = 1 AND join_code IS NOT NULL',
    );
    return [
      for (final r in rows)
        (courseId: r['course_id'] as int, code: r['join_code'] as String),
    ];
  }

  /// The web app turned the join down: the course is left again.
  Future<void> dropMembership(int courseId) => _open.delete(
    'course_membership',
    where: 'course_id = ?',
    whereArgs: [courseId],
  );
}

enum JoinOutcome {
  joined,
  alreadyMember,
  roleUpdated,
  notFound,
  inactive,
  expired,
}
