// Ongoing notification that mirrors the study timer on the lock screen and in the status bar for android
// drawn by system chronometer so app doesn't have to update it every second
//
// When a pomodoro phase ends, a separate alert notification is shown

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Pomodoro phase whose end is announced by [TimerNotification.scheduleEnd].
/// Each has its own notification id, so starting the break doesn't replace
/// the "Pomodoro finished" alert that was just shown.
enum TimerPhase { work, breakTime }

enum NotificationStatus { allowed, appBlocked, channelBlocked }

/// Thrown when the timer notification can't be shown because notifications
/// are blocked.
class NotificationsBlocked implements Exception {
  final NotificationStatus status;
  NotificationsBlocked(this.status);

  @override
  String toString() => status == NotificationStatus.appBlocked
      ? AppLanguage.t.notificationsOffApp
      : AppLanguage.t.notificationsOffTimer;
}

class TimerNotification {
  static const _id = 1;
  static const _channelId = 'study_timer';
  static const _alertChannelId = 'timer_alerts';
  static const _alertIds = {TimerPhase.work: 2, TimerPhase.breakTime: 3};
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _settings = MethodChannel('paola/notification_settings');
  static bool _ready = false;

  /// TODO momentan nur für android
  static bool get supported => Platform.isAndroid;

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static Future<void>? _permission;

  /// Called once the plugin was initialized (see core/util/notifications.dart).
  static void init() {
    if (Platform.isAndroid) _ready = true;
  }

  static Future<void> requestPermission() => _permission = _requestPermission();

  static Future<void> _requestPermission() async {
    if (!_ready) return;
    await _android?.requestNotificationsPermission();
  }

  /// Whether Android will actually show the timer notifications.
  static Future<NotificationStatus> status() async {
    if (!_ready) return NotificationStatus.allowed;
    final android = _android;
    if (await android?.areNotificationsEnabled() == false) {
      return NotificationStatus.appBlocked;
    }
    // Channels only exist after their first notification was posted.
    final channels = await android?.getNotificationChannels() ?? const [];
    final blocked = channels.any(
      (c) =>
          (c.id == _channelId || c.id == _alertChannelId) &&
          c.importance == Importance.none,
    );
    return blocked
        ? NotificationStatus.channelBlocked
        : NotificationStatus.allowed;
  }

  static Future<NotificationStatus> allow() async {
    if (!_ready) return NotificationStatus.allowed;
    await requestPermission();
    final result = await status();
    if (result != NotificationStatus.allowed) {
      await _settings.invokeMethod<void>('open');
    }
    return result;
  }

  /// Counts down to [end]; the notification disappears when it is reached.
  static Future<void> countdown(String title, DateTime end) => _show(
    title,
    when: end,
    countDown: true,
    timeout: end.difference(DateTime.now()),
  );

  /// Counts up from [start].
  static Future<void> stopwatch(String title, DateTime start) =>
      _show(title, when: start, countDown: false);

  /// Static notification while the timer is paused.
  static Future<void> paused(String title, String time) =>
      _show(title, body: AppLanguage.t.pausedAt(time));

  static Future<void> cancel() async {
    if (_ready) await _plugin.cancel(id: _id);
  }

  /// Shows [title]/[body] with sound at [at], when the [phase] ends.
  static Future<void> scheduleEnd(
    TimerPhase phase,
    DateTime at,
    String title,
    String body,
  ) async {
    if (!_ready) return;
    await _permission;
    // Blocked: the alarm would fire but nothing shows; [_show] reports it.
    if (await status() != NotificationStatus.allowed) return;
    final android = _android;
    // Exact alarms are granted via USE_EXACT_ALARM in the manifest; if the
    // system still refuses, the alert may arrive a little late.
    final exact = await android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: _alertIds[phase]!,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          AppLanguage.t.channelAlerts,
          channelDescription: AppLanguage.t.channelAlertsDesc,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          autoCancel: true,
        ),
      ),
    );
  }

  /// Cancels the end alert of [phase], or of both phases (paused or
  /// discarded timer).
  static Future<void> cancelEnd([TimerPhase? phase]) async {
    if (!_ready) return;
    for (final p in phase == null ? TimerPhase.values : [phase]) {
      await _plugin.cancel(id: _alertIds[p]!);
    }
  }

  /// Throws if the notification can't be shown, so the caller can report it.
  static Future<void> _show(
    String title, {
    String? body,
    DateTime? when,
    bool countDown = false,
    Duration? timeout,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_ready) throw StateError('notifications not initialized');
    await _permission;
    final current = await status();
    if (current != NotificationStatus.allowed) {
      throw NotificationsBlocked(current);
    }
    await _plugin.show(
      id: _id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          AppLanguage.t.channelTimer,
          channelDescription: AppLanguage.t.channelTimerDesc,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.stopwatch,
          showWhen: when != null,
          when: when?.millisecondsSinceEpoch,
          usesChronometer: when != null,
          chronometerCountDown: countDown,
          timeoutAfter: timeout?.inMilliseconds,
        ),
      ),
    );
  }
}
