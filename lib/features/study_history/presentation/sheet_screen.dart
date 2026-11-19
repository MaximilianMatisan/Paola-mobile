// Page of one exercise sheet, opened from the sheet menu of the analysis
// tab: its tasks and the timer sessions recorded in its week. Without a
// sheet it lists the sessions that fall outside every sheet's range.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/features/courses/data/course_repository.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/widgets/page_help.dart';
import 'package:paola_mobile/features/study_history/models/exercise_sheet.dart';
import 'package:paola_mobile/features/study_history/presentation/widgets/session_list.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';

class SheetScreen extends StatefulWidget {
  /// The sheet to show; null for the sessions without a sheet.
  final ExerciseSheet? sheet;

  /// All sheets, to find the sessions without one.
  final List<ExerciseSheet> allSheets;

  const SheetScreen({super.key, required this.sheet, required this.allSheets});

  @override
  State<SheetScreen> createState() => _SheetScreenState();
}

class _SheetScreenState extends State<SheetScreen> {
  List<FocusSession> _sessions = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    LocalDatabase.instance.sessionsChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    LocalDatabase.instance.sessionsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await LocalDatabase.instance.sessions(
        courseId: CourseRepository.instance.selectedCourseId.value,
      );
      final sheet = widget.sheet;
      final sessions = sheet != null
          ? all.where(sheet.contains).toList()
          : all
                .where((s) => !widget.allSheets.any((sh) => sh.contains(s)))
                .toList();
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

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: PageHelpButton(
        help: PageHelpContent(
          title: context.t.helpSheetTitle,
          intro: context.t.helpSheetIntro,
          bullets: context.t.helpSheetBullets,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              PageHelpButton.bottomSpace,
            ),
            children: [
              ScreenTitle(
                sheet?.title ?? context.t.sessionsWithoutSheet,
                onBack: () => Navigator.of(context).pop(),
              ),
              if (sheet != null) ...[
                const SizedBox(height: 4),
                SheetSummary(sheet: sheet, showTitle: false),
              ],
              const SizedBox(height: 20),
              SessionStatsRow(totalLabel: context.t.total, sessions: _sessions),
              const SizedBox(height: 16),
              const Hairline(),
              const SizedBox(height: 16),
              const SessionLegend(),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                    ),
                  ),
                )
              else
                SessionDayList(
                  sessions: _sessions,
                  empty: _error != null
                      ? context.t.loadSessionsFailed(_error!)
                      : context.t.noSheetSessions,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title, date range and tasks of [sheet].
class SheetSummary extends StatelessWidget {
  final ExerciseSheet sheet;
  final bool showTitle;

  const SheetSummary({super.key, required this.sheet, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final range = formatDateRange(sheet.validFrom, sheet.validUntil);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Text(
            sheet.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        if (range.isNotEmpty)
          Text(
            range,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
        const SizedBox(height: 12),
        GroupLabel(context.t.tasks),
        const SizedBox(height: 6),
        if (sheet.tasks.isEmpty)
          Text(
            context.t.noTasks,
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final task in sheet.tasks)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    border: Border.all(color: context.colors.line),
                    borderRadius: BorderRadius.circular(PaolaRadius.control),
                  ),
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
