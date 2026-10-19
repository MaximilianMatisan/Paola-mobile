// Live Activity that mirrors the study timer on the lock screen and in the
// Dynamic Island (iOS only, see ios/InteractiveNotificationWidget). It counts
// up the time worked; pause/resume and stop can be pressed there, and the app
// picks those up via [TimerBridge] when it comes back to the foreground.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:interactive_notifications/core/util/constants.dart';
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
  void show({
    required ColorScheme colors,
    required DateTime segmentStart,
    required Duration accumulated,
    required bool paused,
  }) {
    if (!supported) return;
    final data = {
      'currentSegmentStartTimeMs': segmentStart.millisecondsSinceEpoch
          .toString(),
      'accumulatedSeconds': accumulated.inSeconds.toString(),
      'isPaused': paused,
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
