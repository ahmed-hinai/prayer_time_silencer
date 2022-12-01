import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prayer_time_silencer/pages/home.dart';
import 'package:prayer_time_silencer/pages/loading.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';

// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
// @pragma('vm:entry-point')
// void runSilenceScheduler() async {
//   final DateTime now = DateTime.now();
//   final int isolateId = Isolate.current.hashCode;
//   late final LocalNotifications service;
//   service = LocalNotifications();
//   await service.initialize();
//   await service.showNotification(
//       id: 0,
//       title: 'Prayer Time Silencer',
//       body: 'Your Phone is being silenced');
//   await MuteSystemSounds().muteSystemSounds();
//   print("[$now] Hello, world! isolate=${isolateId} function=");
// }

// @pragma('vm:entry-point')
// void runDisableSilenceScheduler() async {
//   final DateTime now = DateTime.now();
//   final int isolateId = Isolate.current.hashCode;
//   late final LocalNotifications service;
//   service = LocalNotifications();
//   await service.initialize();
//   await service.cancelNotification();
//   await MuteSystemSounds().enableSystemSounds();
//   print("[$now] Hello, world! isolate=${isolateId} function=");
// }

void main() async {
  await initializeDateFormatting();
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await LocalNotifications().initialize();
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => Loading(),
      '/home': (context) => Home(),
    },
  ));
}
