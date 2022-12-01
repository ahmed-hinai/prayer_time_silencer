import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tfuck;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:sound_mode/permission_handler.dart';

class LocalNotifications {
  LocalNotifications();

  final localnotification = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@drawable/ic_stat_notifications_off');

    final InitializationSettings settings =
        InitializationSettings(android: androidInitializationSettings);

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await localnotification.pendingNotificationRequests();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    await localnotification.initialize(settings);
  }

  Future<NotificationDetails> _notificationDetails() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('channelId', 'Silenc Notification',
            channelDescription: 'channel_discribtion',
            ongoing: true,
            importance: Importance.max,
            priority: Priority.max,
            playSound: false);

    return NotificationDetails(android: androidNotificationDetails);
  }

  Future<void> showNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime schedule}) async {
    schedule = schedule;
    late var scheduledDate;
    tfuck.initializeTimeZones();
    scheduledDate = tz.TZDateTime.from(schedule,
        tz.getLocation(await FlutterNativeTimezone.getLocalTimezone()));

    final details = await _notificationDetails();
    await localnotification.zonedSchedule(
        id, title, body, scheduledDate, await _notificationDetails(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true);
  }

  Future<void> cancelNotification1() async {
    await localnotification.cancel(9);
  }

  Future<void> cancelNotification2() async {
    await localnotification.cancel(1);
  }

  Future<void> cancelNotification3() async {
    await localnotification.cancel(2);
  }

  Future<void> cancelNotification4() async {
    await localnotification.cancel(3);
  }

  Future<void> cancelNotification5() async {
    await localnotification.cancel(4);
  }
}
