// Horizontal bar per weekday (Monday to Sunday of the current week): green
// for the time the phone lay still, red for the time it was picked up.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';

class WeekChart extends StatelessWidget {
  final List<FocusSession> sessions;

  const WeekChart({super.key, required this.sessions});

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Focused and picked-up time per weekday, index 0 = Monday. Periods are
  /// counted on the day they started.
  List<({Duration still, Duration pickedUp})> _days() {
    final today = _day(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final still = List.filled(7, Duration.zero);
    final pickedUp = List.filled(7, Duration.zero);
    for (final s in sessions) {
      for (final p in s.periods) {
        final i = _day(p.start).difference(monday).inDays;
        if (i < 0 || i > 6) continue;
        if (p.pickedUp) {
          pickedUp[i] += p.duration;
        } else {
          still[i] += p.duration;
        }
      }
    }
    return [
      for (var i = 0; i < 7; i++) (still: still[i], pickedUp: pickedUp[i]),
    ];
  }

  static String _minutes(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    return h > 0 ? '$h h ${m.toString().padLeft(2, '0')}' : '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final days = _days();
    final longest = days.fold(
      Duration.zero,
      (max, d) => d.still + d.pickedUp > max ? d.still + d.pickedUp : max,
    );
    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      children: [
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _DayRow(
              label: context.t.weekdays[i].substring(0, 2),
              still: days[i].still,
              pickedUp: days[i].pickedUp,
              longest: longest,
              total: _minutes(days[i].still + days[i].pickedUp),
              today: i == todayIndex,
            ),
          ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final Duration still;
  final Duration pickedUp;
  final Duration longest;
  final String total;
  final bool today;

  const _DayRow({
    required this.label,
    required this.still,
    required this.pickedUp,
    required this.longest,
    required this.total,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: today ? FontWeight.w600 : FontWeight.w400,
      color: today ? context.colors.textPrimary : context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        SizedBox(width: 28, child: Text(label, style: style)),
        Expanded(
          child: SizedBox(
            height: 14,
            child: CustomPaint(
              painter: _BarPainter(
                still: still,
                pickedUp: pickedUp,
                longest: longest,
                colors: context.colors,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(total, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }
}

/// Track over the full width; the day's time scaled against the longest
/// day: the picked-up part in red from the left, the rest green, so the
/// interruptions line up across days. The red part gets a minimum width so
/// short pick-ups stay visible.
class _BarPainter extends CustomPainter {
  final Duration still;
  final Duration pickedUp;
  final Duration longest;
  final PaolaColors colors;

  _BarPainter({
    required this.still,
    required this.pickedUp,
    required this.longest,
    required this.colors,
  });

  static const _minPickUpWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = colors.track,
    );
    final max = longest.inMilliseconds;
    final total = (still + pickedUp).inMilliseconds;
    if (max == 0 || total == 0) return;

    final width = total / max * size.width;
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, size.height),
      radius,
    );
    canvas.save();
    canvas.clipRRect(bar);
    canvas.drawRect(bar.outerRect, Paint()..color = colors.primary);
    if (pickedUp > Duration.zero) {
      var red = pickedUp.inMilliseconds / max * size.width;
      if (red < _minPickUpWidth) red = _minPickUpWidth;
      canvas.drawRect(
        Rect.fromLTRB(0, 0, red, size.height),
        Paint()..color = colors.error,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.still != still ||
      old.pickedUp != pickedUp ||
      old.longest != longest ||
      old.colors != colors;
}
