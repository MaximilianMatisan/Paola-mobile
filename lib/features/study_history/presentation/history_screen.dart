// Analysis tab: the chart of this week's study time, then the current
// exercise sheet with its tasks and the sessions recorded in its week, then
// a menu of all sheets that opens each sheet's own page (sheet_screen.dart).
// Which sessions belong to a sheet follows from the sheet's date range
// (valid_from / valid_until in the web app, one calendar week per sheet).
// Without any sheets (web app never connected) all sessions are listed.
// With courses, the dropdown in the header picks the course: its sheets and
// the sessions recorded in it (or without a course) are shown.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/widgets/page_help.dart';
import 'package:paola_mobile/features/courses/data/course_repository.dart';
import 'package:paola_mobile/features/courses/presentation/course_switcher.dart';
import 'package:paola_mobile/features/study_history/data/sheet_repository.dart';
import 'package:paola_mobile/features/study_history/models/exercise_sheet.dart';
import 'package:paola_mobile/features/study_history/presentation/sheet_screen.dart';
import 'package:paola_mobile/features/study_history/presentation/widgets/session_list.dart';
import 'package:paola_mobile/features/study_history/presentation/widgets/sheet_menu.dart';
import 'package:paola_mobile/features/study_history/presentation/widgets/week_chart.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';

class HistoryScreen extends StatefulWidget {
  /// Called by the back button in the top left corner.
  final VoidCallback? onBack;

  const HistoryScreen({super.key, this.onBack});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FocusSession> _sessions = [];
  List<ExerciseSheet> _sheets = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    LocalDatabase.instance.sessionsChanged.addListener(_loadSessions);
    CourseRepository.instance.selectedCourseId.addListener(_courseChanged);
    _loadSessions();
    _loadSheets();
  }

  @override
  void dispose() {
    LocalDatabase.instance.sessionsChanged.removeListener(_loadSessions);
    CourseRepository.instance.selectedCourseId.removeListener(_courseChanged);
    super.dispose();
  }

  /// Another course was picked: its stored sheets and sessions, no fetch.
  void _courseChanged() {
    _loadSessions();
    _loadSheets(refresh: false);
  }

  Future<void> _refresh() => Future.wait([_loadSessions(), _loadSheets()]);

  Future<void> _loadSessions() async {
    try {
      final sessions = await LocalDatabase.instance.sessions(
        courseId: CourseRepository.instance.selectedCourseId.value,
      );
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  /// Sheets load on their own, so a slow web app doesn't hold up the
  /// sessions.
  Future<void> _loadSheets({bool refresh = true}) async {
    final sheets = await SheetRepository.instance.sheets(refresh: refresh);
    if (mounted) setState(() => _sheets = sheets);
  }

  List<FocusSession> get _thisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return _sessions.where((s) => !s.start.isBefore(monday)).toList();
  }

  void _openSheet(ExerciseSheet? sheet) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SheetScreen(sheet: sheet, allSheets: _sheets),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = ExerciseSheet.pickCurrent(_sheets);
    final counts = {
      for (final sheet in _sheets)
        sheet.id: _sessions.where(sheet.contains).length,
    };
    final unassigned = _sessions
        .where((s) => !_sheets.any((sheet) => sheet.contains(s)))
        .length;

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: PageHelpButton(
        help: PageHelpContent(
          title: context.t.helpHistoryTitle,
          intro: context.t.helpHistoryIntro,
          bullets: context.t.helpHistoryBullets,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              PageHelpButton.bottomSpace,
            ),
            children: [
              Row(
                children: [
                  ScreenTitle(context.t.history, onBack: widget.onBack),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CourseSwitcher(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GroupLabel(context.t.thisWeek),
              const SizedBox(height: 8),
              WeekChart(sessions: _sessions),
              const SizedBox(height: 20),
              SessionStatsRow(
                totalLabel: context.t.thisWeek,
                sessions: _thisWeek,
              ),
              const SizedBox(height: 16),
              const Hairline(),
              const SizedBox(height: 20),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                    ),
                  ),
                )
              else if (current != null) ...[
                GroupLabel(context.t.currentSheet),
                const SizedBox(height: 4),
                SheetSummary(sheet: current),
                const SizedBox(height: 20),
                const SessionLegend(),
                SessionDayList(
                  sessions: _sessions.where(current.contains).toList(),
                  empty: _error != null
                      ? context.t.loadSessionsFailed(_error!)
                      : context.t.noSheetSessions,
                ),
                const SizedBox(height: 24),
                SheetMenu(
                  sheets: _sheets,
                  current: current,
                  sessionCounts: counts,
                  onOpen: _openSheet,
                  unassignedCount: unassigned,
                  onOpenUnassigned: () => _openSheet(null),
                ),
              ] else ...[
                // No sheets known: all sessions, as before.
                Text(
                  CourseRepository.instance.selectedCourseId.value == null
                      ? context.t.noSheetsHint
                      : context.t.noSheetsInCourse,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const SessionLegend(),
                SessionDayList(
                  sessions: _sessions,
                  empty: _error != null
                      ? context.t.loadSessionsFailed(_error!)
                      : context.t.noSessions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
