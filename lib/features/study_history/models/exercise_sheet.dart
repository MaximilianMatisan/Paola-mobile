// An exercise sheet of a course in the web app (exercise_sheet table) with
// its tasks (exercise table). valid_from / valid_until span the calendar week
// the sheet is worked on (see init-db.sql of the web app); timer sessions
// that started in that range belong to the sheet.
//
// Same rules as utils/sheetSchedule.ts of the web app: a sheet is past after
// valid_until, future before valid_from, and sheets without dates count as
// current.

import 'package:paola_mobile/features/timer/models/focus_session.dart';

enum SheetPhase { active, past, future, undated }

class SheetTask {
  final int id;
  final String title;

  const SheetTask({required this.id, required this.title});

  factory SheetTask.fromJson(Map<String, dynamic> json) => SheetTask(
    id: (json['id'] as num).toInt(),
    title: '${json['title'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

class ExerciseSheet {
  final int id;
  final String title;

  /// First and last day of the sheet (local dates, time 00:00), null if the
  /// sheet has no schedule.
  final DateTime? validFrom;
  final DateTime? validUntil;

  final List<SheetTask> tasks;

  const ExerciseSheet({
    required this.id,
    required this.title,
    this.validFrom,
    this.validUntil,
    this.tasks = const [],
  });

  /// Reads the date part (YYYY-MM-DD) of a stored valid_from / valid_until.
  static DateTime? _date(Object? value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})',
    ).firstMatch('${value ?? ''}'.trim());
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static String? _iso(DateTime? d) => d == null
      ? null
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  factory ExerciseSheet.fromJson(Map<String, dynamic> json) => ExerciseSheet(
    id: (json['id'] as num).toInt(),
    title: '${json['title'] ?? ''}',
    validFrom: _date(json['valid_from']),
    validUntil: _date(json['valid_until']),
    tasks: [
      for (final t in (json['tasks'] as List?) ?? const [])
        SheetTask.fromJson(t as Map<String, dynamic>),
    ],
  );

  ExerciseSheet withTasks(List<SheetTask> tasks) => ExerciseSheet(
    id: id,
    title: title,
    validFrom: validFrom,
    validUntil: validUntil,
    tasks: tasks,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'valid_from': _iso(validFrom),
    'valid_until': _iso(validUntil),
    'tasks': [for (final t in tasks) t.toJson()],
  };

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  SheetPhase phase([DateTime? now]) {
    final today = _day(now ?? DateTime.now());
    final from = validFrom, until = validUntil;
    if (from == null && until == null) return SheetPhase.undated;
    if (from != null && today.isBefore(from)) return SheetPhase.future;
    if (until != null && today.isAfter(until)) return SheetPhase.past;
    return SheetPhase.active;
  }

  /// Whether [session] started within the sheet's date range. Sheets without
  /// dates get no sessions.
  bool contains(FocusSession session) {
    if (validFrom == null && validUntil == null) return false;
    final day = _day(session.start);
    if (validFrom != null && day.isBefore(validFrom!)) return false;
    if (validUntil != null && day.isAfter(validUntil!)) return false;
    return true;
  }

  /// Sorted by start date, sheets without a date last, ties by id.
  static List<ExerciseSheet> sortBySchedule(Iterable<ExerciseSheet> sheets) =>
      [...sheets]..sort((a, b) {
        final fa = a.validFrom, fb = b.validFrom;
        if (fa != null && fb != null && fa != fb) return fa.compareTo(fb);
        if (fa != null && fb == null) return -1;
        if (fa == null && fb != null) return 1;
        return a.id.compareTo(b.id);
      });

  /// The sheet of today: the latest started active one, otherwise the latest
  /// past one, otherwise the first planned one.
  static ExerciseSheet? pickCurrent(
    List<ExerciseSheet> sheets, [
    DateTime? now,
  ]) {
    if (sheets.isEmpty) return null;
    final sorted = sortBySchedule(sheets);
    final active = sorted.where((s) => s.phase(now) == SheetPhase.active);
    if (active.isNotEmpty) return active.last;
    final past = sorted.where((s) => s.phase(now) == SheetPhase.past);
    if (past.isNotEmpty) return past.last;
    return sorted.first;
  }
}
