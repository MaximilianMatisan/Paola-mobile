// Live Activity that mirrors the study timer on the lock screen and in the
// Dynamic Island (iOS only, see ios/InteractiveNotificationWidget). It shows
// the current phase like the dial: pomodoro work and breaks count down,
// stopwatch and flowtime work count up. Pause/resume and stop (during a break:
// discard) can be pressed there, and the app picks those up via [TimerBridge]
// when it comes back to the foreground.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/util/constants.dart';
import 'package:live_activities/live_activities.dart';

class TimerLiveActivity {
  TimerLiveActivity() {
    if (supported) _queue = _plugin.init(appGroupId: appGroupId);
  }

  static bool get supported => Platform.isIOS;

  final _plugin = LiveActivities();
  String? _activityId;

  // Calls run one after another, so a quick start/pause doesn't create two
  // activities.
  Future<void> _queue = Future.value();

  bool get active => _activityId != null;

  /// Starts the activity, or updates it if one is already shown.
  /// [accumulated] is the time elapsed in the current phase. With
  /// [countsDown] the activity shows what is left of [phase] instead.
  /// With [hideTime] it hides the time; the time is still passed along, so
  /// pausing there keeps the app in sync.
  void show({
    required ColorScheme colors,
    required String title,
    required String rateTitle,
    required DateTime segmentStart,
    required Duration accumulated,
    required bool paused,
    required bool countsDown,
    required Duration phase,
    required bool isBreak,
    required bool hideTime,
  }) {
    if (!supported) return;
    final data = {
      'title': title,
      'rateTitle': rateTitle,
      'currentSegmentStartTimeMs': segmentStart.millisecondsSinceEpoch
          .toString(),
      'accumulatedSeconds': accumulated.inSeconds.toString(),
      'isPaused': paused,
      'countsDown': countsDown,
      'phaseSeconds': phase.inSeconds.toString(),
      'isBreak': isBreak,
      'hideTime': hideTime,
    };
    _run(() async {
      if (_activityId == null) {
        // Leftovers, e.g. a self assessment that was never answered.
        await _plugin.endAllActivities();
        _activityId = await _plugin
            .createActivity(DateTime.now().millisecondsSinceEpoch.toString(), {
              'backgroundColor': colors.inversePrimary.toARGB32(),
              'containerColor': colors.secondaryContainer.toARGB32(),
              'textColor': colors.primary.toARGB32(),
              ...data,
            }, iOSEnableRemoteUpdates: false);
        debugPrint('Live Activity started: $_activityId');
      } else {
        await _plugin.updateActivity(_activityId!, data);
        debugPrint('Live Activity updated!');
      }
    });
  }

  void end() {
    if (!supported) return;
    _run(() async {
      if (_activityId == null) return;
      _activityId = null;
      await _plugin.endAllActivities();
      debugPrint('Live Activities ended!');
    });
  }

  void _run(Future<void> Function() action) {
    _queue = _queue.then((_) => action()).catchError((Object e) {
      debugPrint('Live Activity failed: $e');
    });
  }
}
