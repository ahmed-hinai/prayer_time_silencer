import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';

class LocalNotifications {
  LocalNotifications();

  final localnotification = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('@drawable/ic_bg_service_small');

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
        AndroidNotificationDetails('channelId', 'Silence Notification',
            channelDescription: 'channel_discribtion',
            ongoing: true,
            importance: Importance.max,
            priority: Priority.max,
            timeoutAfter: 300000,
            color: Color.fromARGB(255, 7, 64, 111),
            channelShowBadge: false,
            playSound: false,
            enableVibration: false,
            number: 0);

    return const NotificationDetails(android: androidNotificationDetails);
  }

  Future<void> showNotificationBackground({title, body}) async {
    await localnotification.show(
      888,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'foreground_silence', 'FOREGROUND SILENCE SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true,
            enableVibration: false,
            playSound: false,
            color: Color.fromARGB(255, 7, 64, 111),
            colorized: true,
            showWhen: false,
            ticker: '',
            visibility: NotificationVisibility.secret,
            channelShowBadge: false,
            number: 0),
      ),
    );
  }

  Future<void> showNotificationSilence({title, body}) async {
    await localnotification.show(
      888,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'foreground_silence', 'FOREGROUND SILENCE SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true,
            enableVibration: false,
            playSound: false,
            color: Color.fromARGB(255, 0, 0, 0),
            colorized: true,
            showWhen: true,
            visibility: NotificationVisibility.secret,
            channelShowBadge: false,
            timeoutAfter: 5400000,
            number: 0),
      ),
    );
  }

  Future<void> showNotificationNoData({title, body}) async {
    await localnotification.show(
      888,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'foreground_silence', 'FOREGROUND SILENCE SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true,
            enableVibration: false,
            playSound: false,
            color: Color.fromARGB(255, 216, 47, 47),
            colorized: true,
            showWhen: true,
            visibility: NotificationVisibility.secret,
            channelShowBadge: false,
            timeoutAfter: 5400000,
            number: 0),
      ),
    );
  }

  Future<void> cancelNotification() async {
    await localnotification.cancelAll();
  }
}

class ShortLocalNotifications {
  ShortLocalNotifications();

  final localnotification = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings(
            '@drawable/ic_stat_prayer_time_silencer');

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
        AndroidNotificationDetails('channelId', 'Silence Notification',
            channelDescription: 'channel_discribtion',
            ongoing: false,
            importance: Importance.low,
            priority: Priority.low,
            timeoutAfter: 60000,
            playSound: false);

    return const NotificationDetails(android: androidNotificationDetails);
  }

  Future<void> showBackgroundNotification({title, body}) async {
    await localnotification.show(1, title, body, await _notificationDetails());
  }

  Future<void> cancelNotification() async {
    await localnotification.cancelAll();
  }
}
