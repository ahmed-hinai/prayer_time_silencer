import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
// import 'package:prayer_time_silencer/services/set_device_silent.dart';
// import 'package:sound_mode/permission_handler.dart';

class LocalNotifications {
  LocalNotifications();

  final localnotification = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings(
            '@drawable/ic_stat_notifications_off');

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
            styleInformation: BigTextStyleInformation(''),
            playSound: false);

    return const NotificationDetails(android: androidNotificationDetails);
  }

  Future<void> showNotification({title, body}) async {
    await localnotification.show(0, title, body, await _notificationDetails());
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
            '@drawable/ic_stat_notifications_off');

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
