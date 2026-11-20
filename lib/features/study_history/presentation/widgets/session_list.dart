// Building blocks for showing recorded timer sessions, used by the analysis
// overview and the page of a single exercise sheet: stats row, colour legend
// and the sessions grouped by day, each with its timeline.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/widgets/delete_confirmation.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';
import 'package:paola_mobile/features/timer/models/study_activity.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String formatSessionDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '$h h ${_two(m)} min' : '$m min';
}

/// "17.11." or "17.11. – 23.11." for a sheet's date range.
String formatDateRange(DateTime? from, DateTime? until) {
  String short(DateTime d) => '${d.day}.${d.month}.';
  if (from != null && until != null) return '${short(from)} – ${short(until)}';
  if (from != null) return short(from);
  if (until != null) return short(until);
  return '';
}

extension SessionStats on FocusSession {
  int get pickUps => periods.where((p) => p.pickedUp).length;

  Duration get pickedUpTime => periods
      .where((p) => p.pickedUp)
      .fold(Duration.zero, (sum, p) => sum + p.duration);
}

/// Asks, then deletes [s] from the local database. The screens reload via
/// [LocalDatabase.sessionsChanged].
Future<void> deleteSessionWithConfirmation(
  BuildContext context,
  FocusSession s,
) async {
  final mode = s.pomodoro ? context.t.pomodoro : context.t.stopwatch;
  final confirmed = await confirmDelete(
    context,
    title: context.t.discardTitle,
    message: context.t.deleteSessionMessage(
      formatSessionDuration(s.duration),
      mode,
    ),
  );
  if (!confirmed || !context.mounted) return;
  try {
    await LocalDatabase.instance.deleteSession(s);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.deletingFailed(e))));
  }
}

/// Total time, number of sessions and pick-ups of [sessions].
class SessionStatsRow extends StatelessWidget {
  final String totalLabel;
  final List<FocusSession> sessions;

  const SessionStatsRow({
    super.key,
    required this.totalLabel,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final total = sessions.fold(Duration.zero, (sum, s) => sum + s.duration);
    final pickUps = sessions.fold(0, (sum, s) => sum + s.pickUps);
    return Row(
      children: [
        _Stat(totalLabel, formatSessionDuration(total)),
        const SizedBox(width: 32),
        _Stat(context.t.sessions, '${sessions.length}'),
        const SizedBox(width: 32),
        _Stat(context.t.pickedUp, '$pickUps×'),
      ],
    );
  }
}

/// Small grey label with a number below it.
class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Explains the timeline colours.
class SessionLegend extends StatelessWidget {
  const SessionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(context.colors.primary, context.t.phoneResting),
        _LegendItem(context.colors.error, context.t.pickedUp),
        _LegendItem(context.colors.track, context.t.paused),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

/// [sessions] newest first, under a label per calendar day. Shows [empty]
/// if there are none.
class SessionDayList extends StatelessWidget {
  final List<FocusSession> sessions;
  final String empty;

  const SessionDayList({
    super.key,
    required this.sessions,
    required this.empty,
  });

  String _dayLabel(BuildContext context, DateTime day) {
    final diff = _day(DateTime.now()).difference(day).inDays;
    if (diff == 0) return context.t.today;
    if (diff == 1) return context.t.yesterday;
    if (diff > 0 && diff < 7) return context.t.weekdays[day.weekday - 1];
    return '${day.day}.${day.month}.${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          empty,
          style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
        ),
      );
    }
    final sorted = [...sessions]..sort((a, b) => b.start.compareTo(a.start));
    final groups = <DateTime, List<FocusSession>>{};
    for (final s in sorted) {
      groups.putIfAbsent(_day(s.start), () => []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: day, value: daySessions)
            in groups.entries) ...[
          const SizedBox(height: 20),
          GroupLabel(_dayLabel(context, day)),
          for (final s in daySessions)
            _SessionRow(
              title: formatSessionDuration(s.duration),
              meta:
                  '${s.pomodoro ? context.t.pomodoro : context.t.stopwatch}, ${_clock(s.start)}',
              session: s,
              onDelete: () => deleteSessionWithConfirmation(context, s),
            ),
        ],
      ],
    );
  }
}

/// One session: duration and mode, a delete button, the timeline and below
/// it start time, pick-ups and end time. Separated by a line underneath.
class _SessionRow extends StatelessWidget {
  final String title;
  final String meta;
  final FocusSession session;
  final VoidCallback onDelete;

  const _SessionRow({
    required this.title,
    required this.meta,
    required this.session,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontSize: 12, color: context.colors.textSecondary);
    final pickUps = session.pickUps;
    final pickedUp = session.pickedUpTime;
    final pickedUpText = pickedUp.inMinutes > 0
        ? '${pickedUp.inMinutes} min ${pickedUp.inSeconds % 60} s'
        : '${pickedUp.inSeconds} s';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    for (final r in session.reflection ?? const []) ...[
                      const SizedBox(height: 6),
                      _ActivityTag(r),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: context.t.deleteSession,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 6,
            width: double.infinity,
            child: CustomPaint(
              painter: _TimelinePainter(session.periods, context.colors),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(_clock(session.periods.first.start), style: small),
              Expanded(
                child: Text(
                  pickUps == 0
                      ? context.t.notPickedUp
                      : context.t.pickedUpTimes(pickUps, pickedUpText),
                  textAlign: TextAlign.center,
                  style: small.copyWith(
                    color: pickUps == 0 ? null : context.colors.error,
                  ),
                ),
              ),
              Text(_clock(session.periods.last.end), style: small),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTag extends StatelessWidget {
  static const _iconSize = 20.0;

  final ActivityReflection reflection;

  const _ActivityTag(this.reflection);

  @override
  Widget build(BuildContext context) {
    final mood = reflection.rating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mood != null) ...[
          Icon(mood.icon, size: _iconSize, color: mood.color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: ShapeDecoration(
              color: context.colors.primaryContainer,
              shape: const StadiumBorder(),
            ),
            child: Text(
              reflection.activity.label(context.t),
              style: TextStyle(fontSize: 12, color: context.colors.link),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the periods onto the bar, scaled from the first start to the last
/// end; pauses stay in the track colour. Pick-ups are drawn last with a
/// minimum width, so even a few seconds in a long session stay visible.
class _TimelinePainter extends CustomPainter {
  final List<FocusPeriod> periods;
  final PaolaColors colors;

  _TimelinePainter(this.periods, this.colors);

  static const _minPickUpWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(bar, Paint()..color = colors.track);
    canvas.save();
    canvas.clipRRect(bar);

    final first = periods.first.start;
    final total = periods.last.end.difference(first).inMilliseconds;
    double x(DateTime t) => total == 0
        ? 0
        : t.difference(first).inMilliseconds / total * size.width;

    final still = Paint()..color = colors.primary;
    final pickedUp = Paint()..color = colors.error;
    for (final p in periods.where((p) => !p.pickedUp)) {
      canvas.drawRect(
        Rect.fromLTRB(x(p.start), 0, x(p.end), size.height),
        still,
      );
    }
    for (final p in periods.where((p) => p.pickedUp)) {
      var left = x(p.start), right = x(p.end);
      if (right - left < _minPickUpWidth) {
        final mid = (left + right) / 2;
        left = mid - _minPickUpWidth / 2;
        right = mid + _minPickUpWidth / 2;
      }
      canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), pickedUp);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.periods != periods || old.colors != colors;
}
