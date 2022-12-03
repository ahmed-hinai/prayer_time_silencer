import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prayer_time_silencer/pages/home.dart';
import 'package:prayer_time_silencer/pages/loading.dart';
import 'package:prayer_time_silencer/pages/settings.dart';
import 'package:prayer_time_silencer/pages/aboutus.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:background_fetch/background_fetch.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // Do your work here...
  BackgroundFetch.finish(taskId);
}

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
      '/Settings': (context) => Settings(),
      '/About us': (context) => Aboutus()
    },
  ));
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}
