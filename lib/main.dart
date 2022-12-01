import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
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
@pragma('vm:entry-point')
void runSilenceScheduler() async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  Future.delayed(Duration(seconds: 5));
  await MuteSystemSounds().muteSystemSounds();
  print("[$now] Hello, world! isolate=${isolateId} function=");
}

@pragma('vm:entry-point')
void runDisableSilenceScheduler() async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  Future.delayed(Duration(seconds: 1));
  await MuteSystemSounds().enableSystemSounds();
  print("[$now] Hello, world! isolate=${isolateId} function=");
}

@pragma('vm:entry-point')
void runSilenceNotification() async {
  final int isolateId = Isolate.current.hashCode;
  late final LocalNotifications service;
  service = LocalNotifications();
  await service.initialize();
  await service.showNotification(
      id: 0,
      title: 'Prayer Time Silencer',
      body: 'Your Phone is being silenced');
}

@pragma('vm:entry-point')
void cancelSilenceNotification() async {
  final int isolateId = Isolate.current.hashCode;
  late final LocalNotifications service;
  service = LocalNotifications();
  await service.initialize();
  await service.cancelNotification();
}

void main() async {
  await initializeDateFormatting();
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => Loading(),
      '/home': (context) => Home(),
    },
  ));
  final int helloAlarmID = 0;
  try {
    // late Map schedule;
    ScheduleStorage prayerSchedule = ScheduleStorage();
    Map schedule = (await prayerSchedule.readSchedule());
    print(schedule.keys);

    for (String key in schedule.keys) {
      AndroidAlarmManager.oneShotAt(
          DateTime.parse(key), 0, runSilenceScheduler);
      AndroidAlarmManager.oneShotAt(
          DateTime.parse(key), 1, runSilenceNotification);
      AndroidAlarmManager.oneShotAt(
          DateTime.parse(schedule[key]), 2, runDisableSilenceScheduler);
      AndroidAlarmManager.oneShotAt(
          DateTime.parse(schedule[key]), 3, cancelSilenceNotification);
    }
  } catch (e) {
    print(e);
  }
}
