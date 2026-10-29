// Reflection after a pomodoro, same content as the web app's dialog but split
// into steps: 1. which activities, 2. how each went, 3. how the time splits
// between them (skipped with a single activity, it gets all the time).

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/widgets/delete_confirmation.dart';
import 'package:paola_mobile/features/timer/models/mood.dart';
import 'package:paola_mobile/features/timer/models/study_activity.dart';

enum ReflectionAction {
  /// Saved with [ReflectionResult.reflection].
  save,

  /// Closed without answering; the session is still saved.
  skip,

  /// Like [skip], and the next pomodoro starts right away.
  keepStudying,

  /// The session is thrown away.
  discard,
}

class ReflectionResult {
  final ReflectionAction action;
  final List<ActivityReflection>? reflection;

  const ReflectionResult(this.action, [this.reflection]);
}

/// Asks how the [studied] time was spent. Back button and the close icon
/// count as [ReflectionAction.skip].
Future<ReflectionResult> showReflection(
  BuildContext context, {
  required Duration studied,
}) async {
  final result = await showDialog<ReflectionResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: context.colors.scrim,
    builder: (context) => _ReflectionDialog(studied.inSeconds),
  );
  return result ?? const ReflectionResult(ReflectionAction.skip);
}

/// "4 s", "2 min", "1 min 30 s", "1 h 5 min".
String _durationText(int seconds) {
  final h = seconds ~/ 3600, m = seconds % 3600 ~/ 60, s = seconds % 60;
  if (h > 0) return m == 0 ? '$h h' : '$h h $m min';
  if (m > 0) return s == 0 ? '$m min' : '$m min $s s';
  return '$s s';
}

/// Marks the self-study activities (orange dot in the web app).
const _markColor = Color(0xFFF26B21);

class _ReflectionDialog extends StatefulWidget {
  final int total;

  const _ReflectionDialog(this.total);

  @override
  State<_ReflectionDialog> createState() => _ReflectionDialogState();
}

class _ReflectionDialogState extends State<_ReflectionDialog> {
  int _step = 0;
  final _selected = <StudyActivity>{};
  final _ratings = <StudyActivity, Mood>{};
  final _seconds = <StudyActivity, int>{};

  /// Selected activities in list order.
  List<StudyActivity> get _activities => [
    for (final a in StudyActivity.values)
      if (_selected.contains(a)) a,
  ];

  int get _stepCount => _selected.length > 1 ? 3 : 2;
  bool get _lastStep => _step == _stepCount - 1;

  void _toggle(StudyActivity a) {
    setState(() {
      if (!_selected.remove(a)) _selected.add(a);
      _ratings.removeWhere((k, _) => !_selected.contains(k));
      _splitEvenly();
    });
  }

  void _splitEvenly() {
    final activities = _activities;
    _seconds.clear();
    if (activities.isEmpty) return;
    final base = widget.total ~/ activities.length;
    final rest = widget.total % activities.length;
    for (final (i, a) in activities.indexed) {
      _seconds[a] = base + (i < rest ? 1 : 0);
    }
  }

  /// Sets [a] to [value] and scales the others so the sum stays the total.
  void _setSeconds(StudyActivity a, int value) {
    final others = _activities..remove(a);
    final remaining = widget.total - value;
    final othersSum = others.fold(0, (sum, o) => sum + _seconds[o]!);
    var given = 0;
    for (final o in others) {
      final share = othersSum == 0
          ? remaining ~/ others.length
          : _seconds[o]! * remaining ~/ othersSum;
      _seconds[o] = share;
      given += share;
    }
    // Hand out what rounding down left over.
    for (var i = 0; given < remaining; i = (i + 1) % others.length) {
      _seconds[others[i]] = _seconds[others[i]]! + 1;
      given++;
    }
    setState(() => _seconds[a] = value);
  }

  List<ActivityReflection> get _reflection => [
    for (final a in _activities)
      ActivityReflection(
        activity: a,
        rating: _ratings[a],
        seconds: _seconds[a]!,
      ),
  ];

  void _close(ReflectionAction action) => Navigator.of(context).pop(
    ReflectionResult(
      action,
      action == ReflectionAction.save ? _reflection : null,
    ),
  );

  Future<void> _discard() async {
    final confirmed = await confirmDelete(
      context,
      title: context.t.discardTitle,
      message: context.t.discardMessage,
    );
    if (confirmed && mounted) _close(ReflectionAction.discard);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Dialog(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PaolaRadius.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const Hairline(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (_step) {
                  0 => _activitiesStep(),
                  1 => _ratingsStep(),
                  _ => _timeStep(),
                },
              ),
            ),
            const Hairline(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  PaolaButton(
                    label: t.reflectionDiscard,
                    style: PaolaButtonStyle.danger,
                    onPressed: _discard,
                  ),
                  const Spacer(),
                  Flexible(
                    child: PaolaButton(
                      label: t.reflectionContinue,
                      style: PaolaButtonStyle.secondary,
                      onPressed: () => _close(ReflectionAction.keepStudying),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: PaolaButton(
                      label: _lastStep ? t.reflectionSave : t.reflectionNext,
                      onPressed: _selected.isEmpty
                          ? null
                          : _lastStep
                          ? () => _close(ReflectionAction.save)
                          : () => setState(() => _step++),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final material = MaterialLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(_step > 0 ? 4 : 20, 8, 8, 8),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              tooltip: material.backButtonTooltip,
              icon: Icon(Icons.chevron_left, color: context.colors.textPrimary),
              onPressed: () => setState(() => _step--),
            ),
          Expanded(
            child: Text(
              context.t.reflectionTitle(_durationText(widget.total)),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          for (var i = 0; i < _stepCount; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _step
                    ? context.colors.primary
                    : context.colors.track,
              ),
            ),
          IconButton(
            tooltip: material.closeButtonTooltip,
            icon: Icon(Icons.close, color: context.colors.textPrimary),
            onPressed: () => _close(ReflectionAction.skip),
          ),
        ],
      ),
    );
  }

  Widget _activitiesStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Heading(context.t.reflectionActivitiesQuestion),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final a in StudyActivity.values)
            _ActivityChip(
              label: a.label(context.t),
              marked: a.marked,
              selected: _selected.contains(a),
              onTap: () => _toggle(a),
            ),
        ],
      ),
    ],
  );

  Widget _ratingsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, a) in _activities.indexed) ...[
        if (i > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Hairline(),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Heading(context.t.reflectionHowWent(a.label(context.t))),
            ),
            const SizedBox(width: 12),
            _Secondary(_durationText(_seconds[a]!)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (j, mood) in Mood.values.indexed) ...[
              if (j > 0) const SizedBox(width: 6),
              Expanded(
                child: _MoodTile(
                  mood: mood,
                  selected: _ratings[a] == mood,
                  onTap: () => setState(() {
                    if (_ratings[a] == mood) {
                      _ratings.remove(a);
                    } else {
                      _ratings[a] = mood;
                    }
                  }),
                ),
              ),
            ],
          ],
        ),
      ],
    ],
  );

  Widget _timeStep() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Heading(context.t.reflectionTimeTitle)),
            _Secondary(context.t.reflectionSum(_durationText(widget.total))),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.track,
            thumbColor: colors.textSecondary,
            overlayColor: colors.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Column(
            children: [
              for (final a in _activities) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        a.label(context.t),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _durationText(_seconds[a]!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _seconds[a]!.toDouble(),
                  max: widget.total.toDouble(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onChanged: widget.total == 0
                      ? null
                      : (v) => _setSeconds(a, v.round()),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: colors.textSecondary,
          ),
          onPressed: () => setState(_splitEvenly),
          child: Text(
            context.t.reflectionSplitEvenly,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.t.reflectionTimeHint,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: context.colors.textPrimary,
    ),
  );
}

class _Secondary extends StatelessWidget {
  final String text;

  const _Secondary(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
  );
}

/// Pill with the activity name; green outline when selected.
class _ActivityChip extends StatelessWidget {
  final String label;
  final bool marked;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityChip({
    required this.label,
    required this.marked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = StadiumBorder(
      side: selected
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide(color: colors.line, width: 2),
    );
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (marked)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: _markColor,
                      ),
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? colors.link : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Face icon with the mood's name underneath.
class _MoodTile extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodTile({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PaolaRadius.card),
      side: selected
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide(color: colors.line, width: 2),
    );
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(
                mood.icon,
                size: 28,
                color: selected ? colors.link : colors.textPrimary,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mood.label(context.t),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? colors.link : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
