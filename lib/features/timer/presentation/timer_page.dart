import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paola_mobile/features/study_history/presentation/study_history_page.dart';
import 'package:paola_mobile/features/timer/models/mood.dart';
import 'package:paola_mobile/features/timer/presentation/self_assessment_page.dart';
import 'package:paola_mobile/core/util/constants.dart';
import 'package:paola_mobile/features/study_history/presentation/widgets/stacked_cards.dart';
import 'package:paola_mobile/features/timer/presentation/widgets/timer_element.dart';
import 'package:paola_mobile/features/timer/util/timer_bridge.dart';
import 'package:live_activities/live_activities.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  final String title = 'Timer';

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  final _liveActivityPlugin = LiveActivities();
  String? _activityId;

  Timer? _timer;
  int _accumulatedSeconds = 0;
  int _secondsPassed = 0;
  DateTime? _currentSegmentStartTime;
  bool _isPaused = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveActivityPlugin.init(appGroupId: appGroupId);
    _syncFromNative();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncFromNative();
    }
  }

  Future<void> _syncFromNative() async {
    final finalTime = await TimerBridge.consumeFinishedSeconds();
    final moodString = await TimerBridge.consumeSelfAssessmentMoodString();

    if (moodString != null) {
      setState(_resetTimerVariables);
      _activityId = null;
      debugPrint('$moodString mood assessment');
      return;
    }

    if (finalTime != null) {
      setState(_resetTimerVariables);

      _activityId = null;
      if (finalTime > 0) {
        _switchToSelfAssessment();
      }
      return;
    }

    final nativeState = await TimerBridge.getState();

    if (nativeState == null) {
      setState(_resetTimerVariables);
      _activityId = null;
      return;
    }

    final tempIsPaused = nativeState['isPaused'] as bool;
    final tempAccumulatedSeconds = nativeState['accumulatedSeconds'] as int;
    final tempCurrentSegmentStartTime =
        nativeState['currentSegmentStartTimeMs'] as int;

    setState(() {
      _isPaused = tempIsPaused;
      _accumulatedSeconds = tempAccumulatedSeconds;

      _currentSegmentStartTime = _isPaused
          ? null
          : DateTime.fromMillisecondsSinceEpoch(tempCurrentSegmentStartTime);

      _secondsPassed = _isPaused
          ? _accumulatedSeconds
          : _accumulatedSeconds +
                DateTime.now().difference(_currentSegmentStartTime!).inSeconds;
    });

    _timer?.cancel();
    _timer = _isPaused
        ? null
        : Timer.periodic(
            const Duration(seconds: 1),
            (_) => _recalculateSeconds(),
          );
  }

  Future<void> _startLiveActivity(DateTime now) async {
    _activityId = await _liveActivityPlugin
        .createActivity(DateTime.now().millisecondsSinceEpoch.toString(), {
          'backgroundColor': Theme.of(
            context,
          ).colorScheme.inversePrimary.toARGB32(),
          'containerColor': Theme.of(
            context,
          ).colorScheme.secondaryContainer.toARGB32(),
          'textColor': Theme.of(context).colorScheme.primary.toARGB32(),
          'currentSegmentStartTimeMs': now.millisecondsSinceEpoch.toString(),
          'accumulatedSeconds': _accumulatedSeconds.toString(),
          'isPaused': _isPaused,
        }, iOSEnableRemoteUpdates: false);
    debugPrint('Live Activity started: $_activityId');
  }

  Future<void> _updateLiveActivity(DateTime now) async {
    await _liveActivityPlugin.updateActivity(_activityId!, {
      'currentSegmentStartTimeMs': now.millisecondsSinceEpoch.toString(),
      'accumulatedSeconds': _accumulatedSeconds.toString(),
      'isPaused': _isPaused,
    });
    debugPrint('Live Activity updated!');
  }

  Future<void> _endLiveActivities() async {
    await _liveActivityPlugin.endAllActivities();
    _activityId = null;
    debugPrint('Live Activities ended!');
  }

  void _toggleTimer() {
    final now = DateTime.now();
    setState(() {
      if (_isPaused && _timer == null) {
        _currentSegmentStartTime = now;
        _isPaused = false;

        _timer = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _recalculateSeconds(),
        );
      } else {
        _currentSegmentStartTime = null;
        _accumulatedSeconds = _secondsPassed;
        _isPaused = true;

        _timer?.cancel();
        _timer = null;
      }
    });
    if (_activityId == null) {
      _startLiveActivity(now);
    } else {
      _updateLiveActivity(now);
    }
  }

  void _recalculateSeconds() {
    if (!_isPaused && _currentSegmentStartTime != null) {
      int elapsedInCurSegment = DateTime.now()
          .difference(_currentSegmentStartTime!)
          .inSeconds;
      setState(() {
        _secondsPassed = _accumulatedSeconds + elapsedInCurSegment;
      });
    }
  }

  void _endLearningTimer() {
    _endLiveActivities();
    int studiedTime = _resetTimer();
    if (studiedTime > 0) {
      _switchToSelfAssessment();
    }
  }

  int _resetTimer() {
    int finalStudyTime = _secondsPassed;
    setState(() {
      _resetTimerVariables();
    });
    return finalStudyTime;
  }

  void _resetTimerVariables() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    _accumulatedSeconds = 0;
    _secondsPassed = 0;
    _isPaused = true;
    _currentSegmentStartTime = null;
  }

  void _switchToSelfAssessment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SelfAssessmentPage()),
    );
  }
  void _switchToStudyHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudyHistoryPage()),
    );
  }

  // Rerun if setState is called
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 40),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsetsGeometry.all(10),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              TimerElement(
                secondsPassed: _secondsPassed,
                isPaused: _isPaused,
                onPressedToggle: _toggleTimer,
                onPressedReset: _endLearningTimer,
              ),

              Spacer(),
              StackedCard(
                label: 'Yesterday',
                value: '55 Minutes',
                mood: Mood.bad,
                onTap: () => _switchToStudyHistory(),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
