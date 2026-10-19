// History of the timer sessions recorded by this app (focus_period table in db),

import 'package:flutter/material.dart';

import 'package:interactive_notifications/core/network/paola_api.dart';
import 'package:interactive_notifications/core/style/paola_theme.dart';
import 'package:interactive_notifications/core/widgets/delete_confirmation.dart';

class HistoryScreen extends StatefulWidget {
  /// Called by the back button in the top left corner.
  final VoidCallback? onBack;

  const HistoryScreen({super.key, this.onBack});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FocusSession> _sessions = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PaolaApi.instance.sessionsChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    PaolaApi.instance.sessionsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sessions = await PaolaApi.instance.sessions();
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

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dayLabel(DateTime day) {
    final diff = _day(DateTime.now()).difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return _weekdays[day.weekday - 1];
    return '${day.day}.${day.month}.${day.year}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '$h h ${_two(m)} min' : '$m min';
  }

  List<FocusSession> get _thisWeek {
    final today = _day(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return _sessions.where((s) => !s.start.isBefore(monday)).toList();
  }

  Future<void> _delete(FocusSession s) async {
    final mode = s.pomodoro ? 'Pomodoro' : 'Stopwatch';
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this session?',
      message:
          "${_formatDuration(s.duration)} ($mode) will be removed from your "
          "history. This can't be undone.",
    );
    if (!confirmed || !mounted) return;
    try {
      await PaolaApi.instance.deleteSession(s);
      if (mounted) setState(() => _sessions.remove(s));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleting failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = _thisWeek;
    final weekTotal = week.fold(Duration.zero, (sum, s) => sum + s.duration);
    final weekPickUps = week.fold(0, (sum, s) => sum + s.pickUps);

    // Sessions newest first, grouped by calendar day.
    final sorted = [..._sessions]..sort((a, b) => b.start.compareTo(a.start));
    final groups = <DateTime, List<FocusSession>>{};
    for (final s in sorted) {
      groups.putIfAbsent(_day(s.start), () => []).add(s);
    }

    return Scaffold(
      backgroundColor: PaolaColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: PaolaColors.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              ScreenTitle('History', onBack: widget.onBack),
              const SizedBox(height: 20),
              Row(
                children: [
                  _Stat('This week', _formatDuration(weekTotal)),
                  const SizedBox(width: 32),
                  _Stat('Sessions', '${week.length}'),
                  const SizedBox(width: 32),
                  _Stat('Picked up', '$weekPickUps×'),
                ],
              ),
              const SizedBox(height: 16),
              const Hairline(),
              const SizedBox(height: 16),
              const _Legend(),
              if (_loading || _error != null || _sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: PaolaColors.primary,
                          )
                        : Text(
                            _error != null
                                ? 'Could not load sessions: $_error'
                                : 'No sessions yet. Finished timers show up here.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: PaolaColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              for (final MapEntry(key: day, value: sessions)
                  in groups.entries) ...[
                const SizedBox(height: 20),
                GroupLabel(_dayLabel(day)),
                for (final s in sessions)
                  _SessionRow(
                    title: _formatDuration(s.duration),
                    meta:
                        '${s.pomodoro ? 'Pomodoro' : 'Stopwatch'}, ${_clock(s.start)}',
                    session: s,
                    onDelete: () => _delete(s),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on FocusSession {
  int get pickUps => periods.where((p) => p.pickedUp).length;

  Duration get pickedUpTime => periods
      .where((p) => p.pickedUp)
      .fold(Duration.zero, (sum, p) => sum + p.duration);
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
          style: const TextStyle(
            fontSize: 13,
            color: PaolaColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: PaolaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Explains the timeline colours.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(PaolaColors.primary, 'Phone resting'),
        _LegendItem(PaolaColors.error, 'Picked up'),
        _LegendItem(PaolaColors.track, 'Paused'),
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
          style: const TextStyle(
            fontSize: 12,
            color: PaolaColors.textSecondary,
          ),
        ),
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
    const small = TextStyle(fontSize: 12, color: PaolaColors.textSecondary);
    final pickUps = session.pickUps;
    final pickedUp = session.pickedUpTime;
    final pickedUpText = pickedUp.inMinutes > 0
        ? '${pickedUp.inMinutes} min ${pickedUp.inSeconds % 60} s'
        : '${pickedUp.inSeconds} s';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PaolaColors.line)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: PaolaColors.textPrimary,
                      ),
                    ),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PaolaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete session',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: PaolaColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 6,
            width: double.infinity,
            child: CustomPaint(painter: _TimelinePainter(session.periods)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _HistoryScreenState._clock(session.periods.first.start),
                style: small,
              ),
              Expanded(
                child: Text(
                  pickUps == 0
                      ? 'Not picked up'
                      : 'Picked up $pickUps×, $pickedUpText',
                  textAlign: TextAlign.center,
                  style: small.copyWith(
                    color: pickUps == 0 ? null : PaolaColors.error,
                  ),
                ),
              ),
              Text(
                _HistoryScreenState._clock(session.periods.last.end),
                style: small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the periods onto the bar, scaled from the first start to the last
/// end; pauses stay in the track colour. Pick-ups are drawn last with a
/// minimum width, so even a few seconds in a long session stay visible.
class _TimelinePainter extends CustomPainter {
  final List<FocusPeriod> periods;

  _TimelinePainter(this.periods);

  static const _minPickUpWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(bar, Paint()..color = PaolaColors.track);
    canvas.save();
    canvas.clipRRect(bar);

    final first = periods.first.start;
    final total = periods.last.end.difference(first).inMilliseconds;
    double x(DateTime t) => total == 0
        ? 0
        : t.difference(first).inMilliseconds / total * size.width;

    final still = Paint()..color = PaolaColors.primary;
    final pickedUp = Paint()..color = PaolaColors.error;
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
  bool shouldRepaint(_TimelinePainter old) => old.periods != periods;
}
