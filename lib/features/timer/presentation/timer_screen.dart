// stopwatch und pomodoro
// nicht zu study_log geschrieben, TODO dafür ist ein kurs, sheet und excercise nötig, evtl. neu als feature
// stattdessen in focus_period geschrieben
// wenn sensoren bewegung aufnehmen, 10s countdown, bis pausiert wird
// bewegungsphasen und pausen auf history seite einsehbar

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:interactive_notifications/core/network/paola_api.dart';
import 'package:interactive_notifications/features/timer/services/movement_sensor.dart';
import 'package:interactive_notifications/core/style/paola_theme.dart';
import 'package:interactive_notifications/features/timer/util/timer_notification.dart';
import 'package:interactive_notifications/core/widgets/delete_confirmation.dart';
import 'package:interactive_notifications/features/timer/models/timer_mode.dart';
import 'package:interactive_notifications/features/timer/presentation/self_assessment_page.dart';
import 'package:interactive_notifications/features/timer/util/timer_bridge.dart';
import 'package:interactive_notifications/features/timer/util/timer_live_activity.dart';

class TimerScreen extends StatefulWidget {
  final VoidCallback onOpenHistory;

  const TimerScreen({super.key, required this.onOpenHistory});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  static const _breakChoices = [0, 5, 10, 15, 20];
  static const _maxMinutes = 99;
  static const _secondStep = 5;

  TimerMode _mode = TimerMode.pomodoro;
  int _workSeconds = 25 * 60;
  int _breakMinutes = 5;
  bool _onBreak = false;

  // Elapsed time = time banked from earlier runs + time since _runStart.
  Duration _banked = Duration.zero;
  DateTime? _runStart;
  Timer? _ticker;

  late final _sensor = MovementSensor(onTimeout: _onPickedUp);
  final _liveActivity = TimerLiveActivity();
  DateTime? _sessionStart;

  late Future<Duration> _yesterday = _loadYesterday();

  bool get _running => _runStart != null;
  bool get _configuring => !_running && _banked == Duration.zero;
  Duration get _phaseTotal => _onBreak
      ? Duration(minutes: _breakMinutes)
      : Duration(seconds: _workSeconds);

  Duration get _elapsed =>
      _running ? _banked + DateTime.now().difference(_runStart!) : _banked;

  Future<Duration> _loadYesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return PaolaApi.instance.studyTimeOn(y);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _sensor.dispose();
    TimerNotification.cancel();
    _liveActivity.end();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncFromLiveActivity();
  }

  /// Takes over what was pressed in the Live Activity while the app was in the background.
  Future<void> _syncFromLiveActivity() async {
    if (!TimerLiveActivity.supported) return;
    final moodString = await TimerBridge.consumeSelfAssessmentMoodString();
    final finalTime = await TimerBridge.consumeFinishedSeconds();
    if (!mounted) return;

    if (moodString != null || finalTime != null) {
      // Stopped on the lock screen.
      if (moodString != null) debugPrint('$moodString mood assessment');
      if (_configuring) return;
      _finish();
      if (moodString == null && finalTime! > 0) _switchToSelfAssessment();
      return;
    }

    if (_onBreak || !_liveActivity.active) return;
    final nativeState = await TimerBridge.getState();
    if (nativeState == null || !mounted) return;
    final paused = nativeState['isPaused'] as bool;
    final accumulated = Duration(
      seconds: nativeState['accumulatedSeconds'] as int,
    );
    if (paused && _running) {
      _pause(at: accumulated);
    } else if (!paused && !_running) {
      _banked = accumulated;
      _start(
        since: DateTime.fromMillisecondsSinceEpoch(
          nativeState['currentSegmentStartTimeMs'] as int,
        ),
      );
    }
  }

  void _switchToSelfAssessment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SelfAssessmentPage()),
    );
  }

  /// Mirrors the work time in the Live Activity; there is none during breaks.
  void _syncLiveActivity() {
    if (_configuring || _onBreak) {
      _liveActivity.end();
      return;
    }
    _liveActivity.show(
      colors: Theme.of(context).colorScheme,
      segmentStart: _runStart ?? DateTime.now(),
      accumulated: _banked,
      paused: !_running,
    );
  }

  /// [since] resumes a run that was started in the Live Activity.
  void _start({DateTime? since}) {
    if (_configuring) TimerNotification.requestPermission();
    _runStart = since ?? DateTime.now();
    if (!_onBreak) {
      _sessionStart ??= _runStart;
      _sensor.start();
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _syncNotification();
    _syncLiveActivity();
    setState(() {});
  }

  /// [at] is the elapsed time of a pause pressed in the Live Activity.
  void _pause({Duration? at}) {
    _banked = at ?? _elapsed;
    _runStart = null;
    _ticker?.cancel();
    _sensor.stop();
    _syncNotification();
    _syncLiveActivity();
    setState(() {});
  }

  /// [keepAlerts] leaves the end alert that just fired in place.
  void _reset({bool keepAlerts = false}) {
    _ticker?.cancel();
    _sensor.stop();
    _sensor.takePeriods();
    _sessionStart = null;
    _runStart = null;
    _banked = Duration.zero;
    _onBreak = false;
    TimerNotification.cancel();
    if (!keepAlerts) TimerNotification.cancelEnd();
    _liveActivity.end();
    setState(() {});
  }

  Future<void> _confirmReset() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this session?',
      message: "The time you've tracked so far will be discarded.",
    );
    if (confirmed && mounted) _reset();
  }

  /// Pauses because the countdown ran out while the phone was in use.
  void _onPickedUp() {
    _pause();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timer paused: phone was picked up')),
    );
  }

  /// Saves the work session recorded so far with its movement timeline.
  void _saveSession() {
    _sensor.stop();
    final periods = _sensor.takePeriods();
    final start = _sessionStart;
    _sessionStart = null;
    if (start == null || periods.isEmpty) return;
    final session = FocusSession(
      start: start,
      pomodoro: _mode == TimerMode.pomodoro,
      periods: periods,
    );
    PaolaApi.instance.saveSession(session).catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saving the session failed: $e')));
    });
  }

  void _finish() {
    _saveSession();
    _reset();
  }

  void _tick() {
    if (_mode == TimerMode.pomodoro && _elapsed >= _phaseTotal) {
      if (!_onBreak) _saveSession();
      if (!_onBreak && _breakMinutes > 0) {
        _banked = Duration.zero;
        _onBreak = true;
        _start();
        _notify('Pomodoro finished', 'Time for a $_breakMinutes min break!');
      } else {
        final wasBreak = _onBreak;
        _reset(keepAlerts: true);
        _notify(
          wasBreak ? 'Break is over' : 'Pomodoro finished',
          wasBreak ? 'Ready for the next round?' : 'Well done!',
        );
      }
      return;
    }
    setState(() {});
  }

  /// Mirrors the current state in the lock screen notification.
  void _syncNotification() {
    final pomodoro = _mode == TimerMode.pomodoro;
    final title = !pomodoro
        ? 'Stopwatch'
        : _onBreak
        ? 'Break'
        : 'Pomodoro · $_workLabel';
    final elapsed = _elapsed;
    final phase = _onBreak ? TimerPhase.breakTime : TimerPhase.work;
    final Future<void> shown;
    if (!_running) {
      if (pomodoro) TimerNotification.cancelEnd(phase);
      final left = pomodoro ? _phaseTotal - elapsed : elapsed;
      shown = TimerNotification.paused(
        title,
        _format(left).replaceAll(' ', ''),
      );
    } else if (pomodoro) {
      final end = DateTime.now().add(_phaseTotal - elapsed);
      shown = TimerNotification.countdown(title, end);
      final (alertTitle, alertBody) = _onBreak
          ? ('Break is over', 'Ready for the next round?')
          : _breakMinutes > 0
          ? ('Pomodoro finished', 'Time for a $_breakMinutes min break!')
          : ('Pomodoro finished', 'Well done!');
      TimerNotification.scheduleEnd(
        phase,
        end,
        alertTitle,
        alertBody,
      ).catchError((Object e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule the alert: $e')),
        );
      });
    } else {
      shown = TimerNotification.stopwatch(
        title,
        DateTime.now().subtract(elapsed),
      );
    }
    shown.catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          e is NotificationsBlocked
              ? SnackBar(
                  content: Text(
                    '$e, so the lock screen timer and end alert '
                    "can't show.",
                  ),
                  duration: const Duration(seconds: 8),
                  action: SnackBarAction(
                    label: 'Turn on',
                    onPressed: TimerNotification.allow,
                  ),
                )
              : SnackBar(content: Text('Lock screen timer failed: $e')),
        );
    });
  }

  void _notify(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setMode(TimerMode mode) {
    if (mode == _mode) return;
    _reset();
    setState(() => _mode = mode);
  }

  void _setWork(int minutes, int seconds) =>
      setState(() => _workSeconds = minutes * 60 + seconds);

  @override
  Widget build(BuildContext context) {
    final pomodoro = _mode == TimerMode.pomodoro;
    final configuring = _configuring;

    return Scaffold(
      backgroundColor: PaolaColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: PaolaColors.primary,
          onRefresh: () async {
            setState(() => _yesterday = _loadYesterday());
            await _yesterday.catchError((_) => Duration.zero);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              const ScreenTitle('Timer'),
              const SizedBox(height: 24),
              _ModeToggle(
                mode: _mode,
                active: configuring,
                onChanged: _setMode,
              ),
              const SizedBox(height: 24),
              _Dial(
                progress: configuring ? 0 : _progress(),
                child: configuring
                    ? (pomodoro ? _pomodoroSetter() : const _DialTime('00:00'))
                    : _runningDisplay(),
              ),
              if (_running && !_onBreak) ...[
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _sensor,
                  builder: (context, _) => _MovementStatus(_sensor),
                ),
              ],
              const SizedBox(height: 24),
              if (configuring)
                ..._configControls(pomodoro)
              else
                ..._runControls(),
              const SizedBox(height: 24),
              FutureBuilder<Duration>(
                future: _yesterday,
                builder: (context, snap) => _HistoryLink(
                  onTap: widget.onOpenHistory,
                  yesterday: switch (snap) {
                    AsyncSnapshot(hasError: true) => null,
                    AsyncSnapshot(:final data?) =>
                      'Yesterday ${data.inMinutes} min',
                    _ => null,
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _progress() {
    final elapsed = _elapsed;
    if (_mode == TimerMode.stopwatch) {
      // The ring fills once per minute.
      return (elapsed.inMilliseconds % 60000) / 60000;
    }
    final total = _phaseTotal.inMilliseconds;
    return (total - elapsed.inMilliseconds) / total;
  }

  Widget _runningDisplay() {
    final elapsed = _elapsed;
    if (_mode == TimerMode.stopwatch) {
      return _DialTime(_format(elapsed), label: 'Stopwatch');
    }
    return _DialTime(
      _format(_phaseTotal - elapsed),
      label: _onBreak
          ? 'Break, ${_breakLabel(_breakMinutes)}'
          : 'of $_workText',
    );
  }

  Widget _pomodoroSetter() {
    final minutes = _workSeconds ~/ 60;
    final seconds = _workSeconds % 60;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DigitSetter(
          value: minutes,
          unit: 'min',
          max: _maxMinutes,
          step: 1,
          onChanged: (m) => _setWork(m, seconds),
        ),
        // Bottom padding matches the unit label, so the colon sits on the
        // digits' centre line.
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 18),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: PaolaColors.textSecondary,
            ),
          ),
        ),
        _DigitSetter(
          value: seconds,
          unit: 'sec',
          max: 59,
          step: _secondStep,
          onChanged: (sec) => _setWork(minutes, sec),
        ),
      ],
    );
  }

  List<Widget> _configControls(bool pomodoro) => [
    if (pomodoro) ...[
      Row(
        children: [
          const Text(
            'Break',
            style: TextStyle(fontSize: 15, color: PaolaColors.textSecondary),
          ),
          const Spacer(),
          PopupMenuButton<int>(
            initialValue: _breakMinutes,
            color: PaolaColors.surface,
            tooltip: 'Break length',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PaolaRadius.control),
              side: const BorderSide(color: PaolaColors.line),
            ),
            onSelected: (m) => setState(() => _breakMinutes = m),
            itemBuilder: (_) => [
              for (final m in _breakChoices)
                PopupMenuItem(value: m, child: Text(_breakLabel(m))),
            ],
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              decoration: BoxDecoration(
                color: PaolaColors.surface,
                border: Border.all(color: PaolaColors.line),
                borderRadius: BorderRadius.circular(PaolaRadius.control),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _breakLabel(_breakMinutes),
                    style: const TextStyle(
                      fontSize: 15,
                      color: PaolaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: PaolaColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
    ],
    SizedBox(
      width: double.infinity,
      child: PaolaButton(
        label: 'Start',
        onPressed: pomodoro && _workSeconds == 0 ? null : _start,
      ),
    ),
  ];

  List<Widget> _runControls() => [
    Row(
      children: [
        Expanded(
          child: PaolaButton(
            label: _running ? 'Pause' : 'Resume',
            style: PaolaButtonStyle.secondary,
            onPressed: _running ? _pause : _start,
          ),
        ),
        if (!_onBreak) ...[
          const SizedBox(width: 12),
          Expanded(
            child: PaolaButton(label: 'Finish and save', onPressed: _finish),
          ),
        ],
      ],
    ),
    const SizedBox(height: 8),
    PaolaButton(
      label: 'Discard session',
      style: PaolaButtonStyle.danger,
      onPressed: _confirmReset,
    ),
  ];

  String get _workLabel {
    final m = _workSeconds ~/ 60, s = _workSeconds % 60;
    if (s == 0) return '${m}m';
    return m == 0 ? '${s}s' : '${m}m ${s}s';
  }

  /// Work length for the dial, e.g. "25 min" or "1 min 30 s".
  String get _workText {
    final m = _workSeconds ~/ 60, s = _workSeconds % 60;
    if (s == 0) return '$m min';
    return m == 0 ? '$s s' : '$m min $s s';
  }

  static String _breakLabel(int minutes) =>
      minutes == 0 ? 'None' : '$minutes min';

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = d.inSeconds;
    if (s >= 3600) return '${s ~/ 3600}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
    return '${two(s ~/ 60)}:${two(s % 60)}';
  }
}

/// Under the dial: a quiet "Phone resting" line, or a red strip with the
/// countdown after the phone was picked up.
class _MovementStatus extends StatelessWidget {
  final MovementSensor sensor;

  const _MovementStatus(this.sensor);

  @override
  Widget build(BuildContext context) {
    final countdown = sensor.countdown;
    if (countdown == null) {
      final available = sensor.available;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Dot(available ? PaolaColors.primary : PaolaColors.track),
          const SizedBox(width: 8),
          Text(
            available ? 'Phone resting' : 'Motion sensor unavailable',
            style: const TextStyle(
              fontSize: 14,
              color: PaolaColors.textSecondary,
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PaolaColors.errorContainer,
        borderRadius: BorderRadius.circular(PaolaRadius.control),
      ),
      child: Row(
        children: [
          const _Dot(PaolaColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Phone moved. Pausing in $countdown s',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PaolaColors.error,
              ),
            ),
          ),
          Text(
            '$countdown',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: PaolaColors.error,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Pomodoro / Stopwatch switch. The selected mode is dark while the timer
/// can be set up and grey while it runs.
class _ModeToggle extends StatelessWidget {
  final TimerMode mode;
  final bool active;
  final ValueChanged<TimerMode> onChanged;

  const _ModeToggle({
    required this.mode,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: PaolaColors.surface,
        border: Border.all(color: PaolaColors.line),
        borderRadius: BorderRadius.circular(PaolaRadius.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final m in const [TimerMode.pomodoro, TimerMode.stopwatch])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  color: m != mode
                      ? PaolaColors.surface
                      : active
                      ? PaolaColors.textPrimary
                      : PaolaColors.track,
                  child: Text(
                    m == TimerMode.pomodoro ? 'Pomodoro' : 'Stopwatch',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: m == mode ? FontWeight.w500 : FontWeight.w400,
                      color: m != mode
                          ? PaolaColors.textSecondary
                          : active
                          ? PaolaColors.onTextPrimary
                          : PaolaColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin ring with the time in the middle.
class _Dial extends StatelessWidget {
  final double progress;
  final Widget child;

  const _Dial({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, 272.0);
          return SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _RingPainter(progress.clamp(0.0, 1.0)),
              child: Padding(
                padding: EdgeInsets.all(size * 0.14),
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialTime extends StatelessWidget {
  final String time;
  final String? label;

  const _DialTime(this.time, {this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: PaolaColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (label != null)
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              color: PaolaColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Two-digit value with small chevrons above and below and the unit
/// underneath. The value can also be typed.
class _DigitSetter extends StatefulWidget {
  final int value;
  final String unit;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _DigitSetter({
    required this.value,
    required this.unit,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  State<_DigitSetter> createState() => _DigitSetterState();
}

class _DigitSetterState extends State<_DigitSetter> {
  late final _ctrl = TextEditingController(text: _padded);
  final _focus = FocusNode();

  String get _padded => widget.value.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DigitSetter old) {
    super.didUpdateWidget(old);
    // Arrow taps change the value from outside; don't overwrite while typing.
    if (!_focus.hasFocus && _ctrl.text != _padded) _ctrl.text = _padded;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _ctrl.text.length,
      );
    } else {
      _ctrl.text = _padded; // show the (clamped) value with a leading zero
    }
  }

  void _onTyped(String text) {
    final n = int.tryParse(text);
    if (n != null) widget.onChanged(math.min(n, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.keyboard_arrow_up,
          tooltip: 'More',
          onPressed: v < widget.max
              ? () => widget.onChanged(math.min(v + widget.step, widget.max))
              : null,
        ),
        SizedBox(
          width: 76,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: _onTyped,
            onTapOutside: (_) => _focus.unfocus(),
            cursorColor: PaolaColors.primary,
            style: const TextStyle(
              fontSize: 56,
              height: 1.1,
              fontWeight: FontWeight.w300,
              color: PaolaColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.keyboard_arrow_down,
          tooltip: 'Less',
          onPressed: v > 0
              ? () => widget.onChanged(math.max(v - widget.step, 0))
              : null,
        ),
        Text(
          widget.unit,
          style: const TextStyle(
            fontSize: 12,
            color: PaolaColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Icon(
            icon,
            size: 24,
            color: onPressed == null
                ? PaolaColors.track
                : PaolaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - _stroke / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, paint..color = PaolaColors.track);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint..color = PaolaColors.primary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Row between two lines that opens the history, with yesterday's study
/// time on the right.
class _HistoryLink extends StatelessWidget {
  final VoidCallback onTap;
  final String? yesterday;

  const _HistoryLink({required this.onTap, this.yesterday});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: PaolaColors.line),
          ),
        ),
        child: Row(
          children: [
            const Text(
              'History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: PaolaColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (yesterday != null)
              Text(
                yesterday!,
                style: const TextStyle(
                  fontSize: 14,
                  color: PaolaColors.textSecondary,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: PaolaColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
