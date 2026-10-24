import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:paola_mobile/features/timer/util/timer_notification.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  // Notifications are only set up for the phones (e.g. not on Linux).
  if (!Platform.isAndroid && !Platform.isIOS) return;

  const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestSoundPermission: true,
    requestBadgePermission: true,
    defaultPresentAlert: true,
    defaultPresentSound: true,
    defaultPresentBadge: true,
  );
  //TODO take a look at permissions for android
  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('ic_stat_timer'),
    iOS: iOSSettings,
  );

  await _flutterLocalNotificationsPlugin.initialize(settings: initSettings);
  TimerNotification.init();
}
