// stopwatch, pomodoro und flowtime
// nicht zu study_log geschrieben, TODO dafür ist ein kurs, sheet und excercise nötig, evtl. neu als feature
// stattdessen in focus_period geschrieben
// wenn sensoren bewegung aufnehmen, 10s countdown, bis pausiert wird
// bewegungsphasen und pausen auf history seite einsehbar

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:flutter/services.dart';

import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/features/timer/models/focus_session.dart';
import 'package:paola_mobile/features/timer/services/movement_sensor.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/timer/util/timer_notification.dart';
import 'package:paola_mobile/core/widgets/delete_confirmation.dart';
import 'package:paola_mobile/core/widgets/page_help.dart';
import 'package:paola_mobile/features/timer/models/mood.dart';
import 'package:paola_mobile/features/timer/models/timer_mode.dart';
import 'package:paola_mobile/features/timer/presentation/reflection_dialog.dart';
import 'package:paola_mobile/features/timer/util/flowtime.dart';
import 'package:paola_mobile/features/timer/util/hide_time.dart';
import 'package:paola_mobile/features/timer/util/timer_bridge.dart';
import 'package:paola_mobile/features/timer/util/timer_live_activity.dart';

class TimerScreen extends StatefulWidget {
  final VoidCallback onOpenHistory;

  const TimerScreen({super.key, required this.onOpenHistory});

  @override
  State<TimerScreen> createState() => TimerScreenState();
}

class TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  static const _breakChoices = [0, 5, 10, 15, 20];
  static const _maxMinutes = 99;
  static const _secondChoices = [0, 30];

  TimerMode _mode = TimerMode.pomodoro;
  int _workSeconds = 25 * 60;
  int _breakMinutes = 5;
  bool _onBreak = false;

  /// Length of the current flowtime break, set from the study block before it.
  int _flowBreakMinutes = 0;

  // Elapsed time = time banked from earlier runs + time since _runStart.
  Duration _banked = Duration.zero;
  DateTime? _runStart;
  Timer? _ticker;

  late final _sensor = MovementSensor(onTimeout: _onPickedUp);
  final _liveActivity = TimerLiveActivity();
  DateTime? _sessionStart;

  /// Study blocks finished before a break. They are saved together with the
  /// current block, as one session, when the user finishes.
  final _blocks = <FocusSession>[];

  late Future<Duration> _yesterday = _loadYesterday();

  bool get _running => _runStart != null;

  /// Whether the timer is counting
  bool get isRunning => _running;

  bool get _configuring =>
      !_running && _banked == Duration.zero && _blocks.isEmpty && !_onBreak;
  Duration get _phaseTotal => _onBreak
      ? Duration(minutes: _currentBreakMinutes)
      : Duration(seconds: _workSeconds);

  int get _currentBreakMinutes =>
      _mode == TimerMode.flowtime ? _flowBreakMinutes : _breakMinutes;

  /// In flowtime the dial ends the study block instead of pausing it, since
  /// stopping when focus runs out is what earns the break.
  bool get _flowStudying =>
      _mode == TimerMode.flowtime && _running && !_onBreak;

  /// Pomodoro work and every break count down; stopwatch and flowtime work
  /// count up.
  bool get _countingDown => _mode == TimerMode.pomodoro || _onBreak;

  Duration get _elapsed =>
      _running ? _banked + DateTime.now().difference(_runStart!) : _banked;

  Future<Duration> _loadYesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return LocalDatabase.instance.studyTimeOn(y);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HideTime.enabled.addListener(_onHideTimeChanged);
    _dropStaleLiveActivityResults();
    // A reminder from before the app was (re)started belongs to no timer.
    TimerNotification.cancelReminder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HideTime.enabled.removeListener(_onHideTimeChanged);
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

  /// A Live Activity and its results from before the app was (re)started
  /// belong to no session; left in place the activity would stay on the lock
  /// screen and the results would show the rating in the next one.
  Future<void> _dropStaleLiveActivityResults() async {
    if (!TimerLiveActivity.supported) return;
    _liveActivity.endLeftovers();
    await TimerBridge.consumeSelfAssessmentMoodString();
    await TimerBridge.consumeFinishedSeconds();
    await TimerBridge.consumeFinishedAtMs();
    await TimerBridge.consumeBreakDiscarded();
  }

  /// Takes over what was pressed in the Live Activity while the app was in the background.
  Future<void> _syncFromLiveActivity() async {
    if (!TimerLiveActivity.supported) return;
    final moodString = await TimerBridge.consumeSelfAssessmentMoodString();
    final finishedSeconds = await TimerBridge.consumeFinishedSeconds();
    final finishedAtMs = await TimerBridge.consumeFinishedAtMs();
    final breakDiscarded = await TimerBridge.consumeBreakDiscarded() ?? false;
    if (!mounted) return;

    if (breakDiscarded) {
      if (_onBreak) _discardBreak();
      return;
    }

    if (finishedSeconds != null) {
      _finishFromLiveActivity(
        at: finishedAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(finishedAtMs),
        mood: Mood.values.asNameMap()[moodString],
      );
      return;
    }

    if (!_liveActivity.active) return;
    final nativeState = await TimerBridge.getState();
    if (nativeState == null || !mounted) return;
    final paused = nativeState['isPaused'] as bool;
    final accumulated = Duration(
      seconds: nativeState['accumulatedSeconds'] as int,
    );
    final segmentStart = DateTime.fromMillisecondsSinceEpoch(
      nativeState['currentSegmentStartTimeMs'] as int,
    );
    if (paused && _running) {
      _pause(at: accumulated, stoppedAt: segmentStart);
    } else if (!paused && !_running) {
      _banked = accumulated;
      _start(since: segmentStart);
    }
  }

  /// Stopped on the lock screen [at] that moment: ends the whole session up
  /// to then and asks for the reflection. The [mood] rated on the lock screen
  /// is preset there.
  Future<void> _finishFromLiveActivity({DateTime? at, Mood? mood}) async {
    if (_configuring) return;
    if (_onBreak) {
      // Breaks have a discard button instead.
      _discardBreak();
      return;
    }
    _sensor.stop(at: at);
    final session = _takeWholeSession();
    _reset();
    if (session == null) return;
    final result = await showReflection(
      context,
      studied: session.duration,
      initialMood: mood,
      canKeepStudying: false,
    );
    if (!mounted) return;
    switch (result.action) {
      case ReflectionAction.save:
        _save(session.withReflection(result.reflection, hadAhaMoment: result.hadAhaMoment));
      case ReflectionAction.skip:
        _save(session.withReflection(null, hadAhaMoment: result.hadAhaMoment));
      case ReflectionAction.discard:
      case ReflectionAction.keepStudying:
        break;
    }
  }

  String get _phaseTitle {
    final t = context.t;
    if (_onBreak) return t.breakLabel;
    return switch (_mode) {
      TimerMode.stopwatch => t.stopwatch,
      TimerMode.flowtime => t.flowtime,
      TimerMode.pomodoro => '${t.pomodoro} · $_workLabel',
    };
  }

  /// Mirrors the current phase (work or break) in the Live Activity.
  void _syncLiveActivity() {
    if (_configuring) {
      _liveActivity.end();
      return;
    }
    _liveActivity.show(
      colors: Theme.of(context).colorScheme,
      title: _phaseTitle,
      rateTitle: context.t.rateSession,
      segmentStart: _runStart ?? DateTime.now(),
      accumulated: _banked,
      paused: !_running,
      countsDown: _countingDown,
      phase: _phaseTotal,
      isBreak: _onBreak,
      hideTime: HideTime.enabled.value && !_onBreak,
    );
  }

  /// The setting was switched while a Live Activity is shown.
  void _onHideTimeChanged() {
    if (_liveActivity.active) _syncLiveActivity();
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

  /// [at] is the elapsed time of a pause pressed in the Live Activity,
  /// [stoppedAt] the moment it was pressed.
  void _pause({Duration? at, DateTime? stoppedAt}) {
    _banked = at ?? _elapsed;
    _runStart = null;
    _ticker?.cancel();
    _sensor.stop(at: stoppedAt);
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
    _blocks.clear();
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
      title: context.t.discardTitle,
      message: context.t.discardMessage,
    );
    if (confirmed && mounted) _reset();
  }

  /// Pauses because the countdown ran out while the phone was in use.
  void _onPickedUp() {
    _pause();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.pausedPickedUp)));
  }

  /// Stops recording and hands out the current study block, if there is one.
  FocusSession? _takeSession() {
    _sensor.stop();
    final periods = _sensor.takePeriods();
    final start = _sessionStart;
    _sessionStart = null;
    if (start == null || periods.isEmpty) return null;
    return FocusSession(
      start: start,
      pomodoro: _mode == TimerMode.pomodoro,
      periods: periods,
    );
  }

  /// Puts the current study block aside until the session is finished.
  void _keepBlock() {
    final block = _takeSession();
    if (block != null) _blocks.add(block);
  }

  /// All blocks of the session so far as one session; the breaks between
  /// them are gaps, like pauses. Null if nothing was recorded.
  FocusSession? _takeWholeSession() {
    _keepBlock();
    if (_blocks.isEmpty) return null;
    final session = FocusSession(
      start: _blocks.first.start,
      pomodoro: _mode == TimerMode.pomodoro,
      periods: [for (final b in _blocks) ...b.periods],
    );
    _blocks.clear();
    return session;
  }

  void _save(FocusSession session) {
    LocalDatabase.instance.saveSession(session).catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.saveSessionFailed(e))));
    });
  }

  /// "Finish and save": holds the timer and asks for the reflection.
  /// "Keep studying" carries on where the session was.
  Future<void> _finishWithReflection() async {
    final wasRunning = _running;
    if (wasRunning) _pause();
    final session = _takeWholeSession();
    if (session == null) {
      _reset();
      return;
    }
    final result = await showReflection(context, studied: session.duration);
    if (!mounted) return;
    switch (result.action) {
      case ReflectionAction.keepStudying:
        _blocks.add(session);
        if (wasRunning) _start();
        setState(() {});
        return;
      case ReflectionAction.save:
        _save(session.withReflection(result.reflection, hadAhaMoment: result.hadAhaMoment));
      case ReflectionAction.skip:
        _save(session.withReflection(null, hadAhaMoment: result.hadAhaMoment));
      case ReflectionAction.discard:
        break;
    }
    _reset();
  }

  /// Discarded on the lock screen: only the break ends, the blocks before it
  /// are not saved yet and the session stays open.
  void _discardBreak() {
    TimerNotification.cancelEnd(TimerPhase.breakTime);
    _idle();
  }

  /// Between two blocks: nothing runs and tapping the dial starts the next
  /// block. The end alert that just fired stays.
  void _idle() {
    _ticker?.cancel();
    _sensor.stop();
    _runStart = null;
    _banked = Duration.zero;
    _onBreak = false;
    TimerNotification.cancel();
    _liveActivity.end();
    setState(() {});
  }

  void _tick() {
    if (_countingDown && _elapsed >= _phaseTotal) {
      if (_onBreak) {
        _idle();
        _notify(context.t.breakOver, context.t.nextRound);
        return;
      }
      _keepBlock();
      _banked = Duration.zero;
      if (_breakMinutes > 0) {
        _onBreak = true;
        _start();
      } else {
        _idle();
      }
      _notify(
        context.t.pomodoroFinished,
        _breakMinutes > 0
            ? context.t.breakTime(_breakMinutes)
            : context.t.wellDone,
      );
      return;
    }
    setState(() {});
  }

  /// Ends the flowtime study block and starts the break it earned.
  void _takeBreak() {
    _flowBreakMinutes = flowtimeBreakMinutes(_elapsed);
    _keepBlock();
    _banked = Duration.zero;
    _onBreak = true;
    _start();
  }

  /// Ends the break early and starts the next study block.
  void _skipBreak() {
    TimerNotification.cancelEnd(TimerPhase.breakTime);
    _onBreak = false;
    _banked = Duration.zero;
    _start();
  }

  /// Mirrors the current state in the lock screen notification.
  void _syncNotification() {
    final t = context.t;
    final countdown = _countingDown;
    final title = _phaseTitle;
    final elapsed = _elapsed;
    final phase = _onBreak ? TimerPhase.breakTime : TimerPhase.work;
    // Counting down ends by itself; only an open-ended run can be forgotten.
    // Not being able to remind is no reason to bother the user.
    if (_running && !countdown) {
      TimerNotification.scheduleReminder(
        _runStart!.add(TimerNotification.reminderAfter),
      ).catchError((Object _) {});
    } else {
      TimerNotification.cancelReminder();
    }
    final Future<void> shown;
    if (!_running) {
      if (countdown) TimerNotification.cancelEnd(phase);
      final left = countdown ? _phaseTotal - elapsed : elapsed;
      shown = TimerNotification.paused(
        title,
        _format(left).replaceAll(' ', ''),
      );
    } else if (countdown) {
      final end = DateTime.now().add(_phaseTotal - elapsed);
      shown = TimerNotification.countdown(title, end);
      final (alertTitle, alertBody) = _onBreak
          ? (t.breakOver, t.nextRound)
          : _breakMinutes > 0
          ? (t.pomodoroFinished, t.breakTime(_breakMinutes))
          : (t.pomodoroFinished, t.wellDone);
      TimerNotification.scheduleEnd(
        phase,
        end,
        alertTitle,
        alertBody,
      ).catchError((Object e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.scheduleAlertFailed(e))));
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
                  content: Text(t.notificationsBlockedHint(e)),
                  duration: const Duration(seconds: 8),
                  action: SnackBarAction(
                    label: t.turnOn,
                    onPressed: TimerNotification.allow,
                  ),
                )
              : SnackBar(content: Text(t.lockScreenFailed(e))),
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
            child: Text(context.t.ok),
          ),
        ],
      ),
    );
  }

  void _setMode(TimerMode mode) {
    // The mode is fixed while a session runs (the toggle is greyed out).
    if (mode == _mode || !_configuring) return;
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
      backgroundColor: context.colors.background,
      floatingActionButton: PageHelpButton(help: _help(context.t)),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async {
            setState(() => _yesterday = _loadYesterday());
            await _yesterday.catchError((_) => Duration.zero);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              PageHelpButton.bottomSpace,
            ),
            children: [
              ScreenTitle(context.t.timerTitle),
              const SizedBox(height: 24),
              _ModeToggle(
                mode: _mode,
                active: configuring,
                onChanged: _setMode,
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: HideTime.enabled,
                builder: (context, _) => _dial(pomodoro, configuring),
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
                    AsyncSnapshot(:final data?) => context.t.yesterdayMinutes(
                      data.inMinutes,
                    ),
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

  /// Help text for the selected timer mode.
  PageHelpContent _help(Translations t) => switch (_mode) {
    TimerMode.pomodoro => PageHelpContent(
      title: t.helpPomodoroTitle,
      intro: t.helpPomodoroIntro,
      bullets: t.helpPomodoroBullets,
    ),
    TimerMode.stopwatch => PageHelpContent(
      title: t.helpStopwatchTitle,
      intro: t.helpStopwatchIntro,
      bullets: t.helpStopwatchBullets,
    ),
    TimerMode.flowtime => PageHelpContent(
      title: t.helpFlowtimeTitle,
      intro: t.helpFlowtimeIntro,
      bullets: t.helpFlowtimeBullets,
    ),
  };

  Widget _dial(bool pomodoro, bool configuring) {
    // With the time hidden the ring stays empty too, since it would show
    // the progress.
    final hidden = HideTime.enabled.value && !configuring && !_onBreak;
    return _Dial(
      progress: configuring || hidden ? 0 : _progress(),
      hint: _flowStudying
          ? context.t.tapForBreak
          : _running
          ? context.t.tapToPause
          : configuring
          ? context.t.tapToStart
          : context.t.tapToResume,
      onTap: _flowStudying
          ? _takeBreak
          : _running
          ? _pause
          : pomodoro && configuring && _workSeconds == 0
          ? null
          : _start,
      child: configuring
          ? (pomodoro ? _pomodoroSetter() : const _DialTime('00:00'))
          : hidden
          ? _HiddenTime(
              running: _running,
              label: switch (_mode) {
                TimerMode.pomodoro => context.t.ofWork(_workText),
                TimerMode.flowtime => context.t.flowtime,
                TimerMode.stopwatch => context.t.stopwatch,
              },
            )
          : _runningDisplay(),
    );
  }

  double _progress() {
    final elapsed = _elapsed;
    if (!_countingDown) {
      // The ring fills once per minute.
      return (elapsed.inMilliseconds % 60000) / 60000;
    }
    final total = _phaseTotal.inMilliseconds;
    return (total - elapsed.inMilliseconds) / total;
  }

  Widget _runningDisplay() {
    final elapsed = _elapsed;
    if (!_countingDown) {
      return _DialTime(
        _format(elapsed),
        label: _mode == TimerMode.flowtime
            ? context.t.flowtimeEarned(flowtimeBreakMinutes(elapsed))
            : context.t.stopwatch,
      );
    }
    return _DialTime(
      _format(_phaseTotal - elapsed),
      label: _onBreak
          ? context.t.breakWithLength(_breakLabel(_currentBreakMinutes))
          : context.t.ofWork(_workText),
    );
  }

  Widget _pomodoroSetter() {
    final minutes = _workSeconds ~/ 60;
    final seconds = _workSeconds % 60;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WheelSetter(
          values: [for (var m = 0; m <= _maxMinutes; m++) m],
          value: minutes,
          unit: context.t.unitMin,
          onChanged: (m) => _setWork(m, seconds),
        ),
        // Bottom padding matches the unit label, so the colon sits on the
        // digits' centre line.
        Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 18),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        _WheelSetter(
          values: _secondChoices,
          value: seconds,
          unit: context.t.unitSec,
          onChanged: (sec) => _setWork(minutes, sec),
        ),
      ],
    );
  }

  List<Widget> _configControls(bool pomodoro) => [
    if (pomodoro) ...[
      Row(
        children: [
          Text(
            context.t.breakLabel,
            style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
          ),
          const Spacer(),
          PopupMenuButton<int>(
            initialValue: _breakMinutes,
            color: context.colors.surface,
            tooltip: context.t.breakLength,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PaolaRadius.control),
              side: BorderSide(color: context.colors.line),
            ),
            onSelected: (m) => setState(() => _breakMinutes = m),
            itemBuilder: (_) => [
              for (final m in _breakChoices)
                PopupMenuItem(value: m, child: Text(_breakLabel(m))),
            ],
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border.all(color: context.colors.line),
                borderRadius: BorderRadius.circular(PaolaRadius.control),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _breakLabel(_breakMinutes),
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
    ],
    if (_mode == TimerMode.flowtime) ...[
      // Text(
      //   context.t.flowtimeHint,
      //   style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
      // ),
    ],
    SizedBox(
      width: double.infinity,
      child: PaolaButton(
        label: context.t.start,
        onPressed: pomodoro && _workSeconds == 0 ? null : _start,
      ),
    ),
  ];

  List<Widget> _runControls() => [
    // Pausing and resuming is done by tapping the dial.
    SizedBox(
      width: double.infinity,
      child: PaolaButton(
        label: context.t.finishAndSave,
        onPressed: _finishWithReflection,
      ),
    ),
    const SizedBox(height: 8),
    if (_onBreak) ...[
      SizedBox(
        width: double.infinity,
        child: PaolaButton(
          label: context.t.skipBreak,
          style: PaolaButtonStyle.secondary,
          onPressed: _skipBreak,
        ),
      ),
      const SizedBox(height: 8),
    ],
    PaolaButton(
      label: context.t.discardSession,
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

  String _breakLabel(int minutes) =>
      minutes == 0 ? context.t.breakNone : '$minutes min';

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
          _Dot(available ? context.colors.primary : context.colors.track),
          const SizedBox(width: 8),
          Text(
            available ? context.t.phoneResting : context.t.sensorUnavailable,
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: BorderRadius.circular(PaolaRadius.control),
      ),
      child: Row(
        children: [
          _Dot(context.colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t.phoneMoved(countdown),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.error,
              ),
            ),
          ),
          Text(
            '$countdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.colors.error,
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

/// Pomodoro / Flowtime / Stopwatch switch. The selected mode is dark while the timer
/// can be set up and grey/unchangeable while it runs.
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
        color: context.colors.surface,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(PaolaRadius.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final m in const [
            TimerMode.pomodoro,
            TimerMode.flowtime,
            TimerMode.stopwatch,
          ])
            Expanded(
              child: GestureDetector(
                onTap: active ? () => onChanged(m) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  color: m != mode
                      ? context.colors.surface
                      : active
                      ? context.colors.textPrimary
                      : context.colors.track,
                  child: Text(
                    switch (m) {
                      TimerMode.pomodoro => context.t.pomodoro,
                      TimerMode.flowtime => context.t.flowtime,
                      TimerMode.stopwatch => context.t.stopwatch,
                    },
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: m == mode ? FontWeight.w500 : FontWeight.w400,
                      color: m != mode
                          ? context.colors.textSecondary
                          : active
                          ? context.colors.onTextPrimary
                          : context.colors.textPrimary,
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

/// Thin ring with the time in the middle. Tapping it starts, pauses or
/// resumes the timer; [hint] above the time says which.
class _Dial extends StatelessWidget {
  final double progress;
  final String hint;
  final VoidCallback? onTap;
  final Widget child;

  const _Dial({
    required this.progress,
    required this.hint,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, 272.0);
          return SizedBox.square(
            dimension: size,
            child: Semantics(
              button: true,
              label: hint,
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress.clamp(0.0, 1.0),
                      context.colors,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.14),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hint,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: context.colors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (label != null)
          Text(
            label!,
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
      ],
    );
  }
}

class _HiddenTime extends StatefulWidget {
  final bool running;
  final String label;

  const _HiddenTime({required this.running, required this.label});

  @override
  State<_HiddenTime> createState() => _HiddenTimeState();
}

class _HiddenTimeState extends State<_HiddenTime>
    with SingleTickerProviderStateMixin {
  static const _dotCount = 3;

  late final _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.running) _wave.repeat();
  }

  @override
  void didUpdateWidget(_HiddenTime old) {
    super.didUpdateWidget(old);
    if (widget.running && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!widget.running && _wave.isAnimating) {
      _wave.reset();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  /// 0.25 base opacity
  /// increasing to 1 if wave passes dot i
  double _opacity(int i) {
    if (!widget.running) return 0.25;
    final phase = (_wave.value - i / _dotCount) % 1.0;
    return 0.25 + 0.75 * math.max(0.0, math.sin(phase * 2 * math.pi));
  }

  static const double _heightOfNumbersDisplay = 77;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _heightOfNumbersDisplay,
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _dotCount; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Opacity(
                      opacity: _opacity(i),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

/// Two-digit value on a wheel that is scrolled up and down, with the unit
/// underneath.
class _WheelSetter extends StatefulWidget {
  final List<int> values;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;

  const _WheelSetter({
    required this.values,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_WheelSetter> createState() => _WheelSetterState();
}

class _WheelSetterState extends State<_WheelSetter> {
  static const _itemHeight = 64.0;

  late final _ctrl = FixedExtentScrollController(
    initialItem: math.max(widget.values.indexOf(widget.value), 0),
  );

  /// The wheel loops, so its item index keeps counting past the list.
  int get _shown => widget.values[_ctrl.selectedItem % widget.values.length];

  @override
  void didUpdateWidget(_WheelSetter old) {
    super.didUpdateWidget(old);
    final i = widget.values.indexOf(widget.value);
    if (i >= 0 && _ctrl.hasClients && _shown != widget.value) {
      _ctrl.jumpToItem(i);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 84,
          height: _itemHeight * 2.4,
          child: ListWheelScrollView.useDelegate(
            controller: _ctrl,
            itemExtent: _itemHeight,
            diameterRatio: 1.6,
            overAndUnderCenterOpacity: 0.3,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              HapticFeedback.selectionClick();
              widget.onChanged(widget.values[i % widget.values.length]);
            },
            childDelegate: ListWheelChildLoopingListDelegate(
              children: [
                for (final v in widget.values)
                  Center(
                    child: Text(
                      v.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 56,
                        height: 1.1,
                        fontWeight: FontWeight.w300,
                        color: context.colors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          widget.unit,
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final PaolaColors colors;

  _RingPainter(this.progress, this.colors);

  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - _stroke / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, paint..color = colors.track);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint..color = colors.primary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colors != colors;
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
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: context.colors.line),
          ),
        ),
        child: Row(
          children: [
            Text(
              context.t.history,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),
            if (yesterday != null)
              Text(
                yesterday!,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
