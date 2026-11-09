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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _file = 'paola.db';
  static const _version = 1;
  static const _sessions = 'focus_sessions';

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
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_sessions (
          session_start INTEGER PRIMARY KEY,
          is_pomodoro INTEGER NOT NULL,
          periods TEXT NOT NULL,
          reflection TEXT,
          had_aha_moment INTEGER NOT NULL DEFAULT 0,
          on_server INTEGER NOT NULL DEFAULT 0,
          pending INTEGER NOT NULL DEFAULT 1,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      '''),
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
      });

  /// Stores [session], replacing one with the same start, and marks it to be
  /// sent to the web app.
  Future<void> saveSession(FocusSession session) async {
    final row = _toRow(session);
    await _open.transaction((txn) async {
      final updated = await txn.update(
        _sessions,
        {...row, 'pending': 1, 'deleted': 0},
        where: 'session_start = ?',
        whereArgs: [row['session_start']],
      );
      if (updated == 0) await txn.insert(_sessions, row);
    });
    sessionsChanged.value++;
  }

  /// Recorded sessions that aren't deleted, newest first.
  Future<List<FocusSession>> sessions() async {
    final rows = await _open.query(
      _sessions,
      where: 'deleted = 0',
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
}
