import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:prayer_time_silencer/pages/home.dart';
import 'package:prayer_time_silencer/pages/loading.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:prayer_time_silencer/templates/timeObject.dart';

// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void runSilenceScheduler() async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function=");
  await MuteSystemSounds().muteSystemSounds();
}

void main() async {
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
  await AndroidAlarmManager.periodic(
      const Duration(minutes: 1), helloAlarmID, runSilenceScheduler);
  print('this is a test for something ${TimeObject(time: '12:25').setTime()}');
}
