import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotifications {
  LocalNotifications();

  final _localnotification = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@drawable/ic_stat_notifications_off');

    final InitializationSettings settings =
        InitializationSettings(android: androidInitializationSettings);

    await _localnotification.initialize(settings);
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
      {required int id, required String title, required String body}) async {
    final details = await _notificationDetails();
    await _localnotification.show(id, title, body, details);
  }

  Future<void> cancelNotification() async {
    await _localnotification.cancel(0);
  }
}
