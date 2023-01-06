import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:prayer_time_silencer/services/wait_and_prewait_store.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final int day = DateTime.now().day;
final int month = DateTime.now().month;
final int year = DateTime.now().year;
Map<String, DateTime> prayers = {};
Map<String, String> scheduleStart = {};
Map<String, String> scheduleEnd = {};

@pragma('vm:entry-point')
void createSilence() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);
  LocalNotifications instance = LocalNotifications();
  instance.showNotificationSilence(
      title: l10n.notificationTitle, body: l10n.notificationBody);

  await MuteSystemSounds().muteSystemSounds();
}

@pragma('vm:entry-point')
void disableSilence() async {
  await MuteSystemSounds().enableSystemSounds();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);
  LocalNotifications instance = LocalNotifications();
  await instance.showNotificationBackground(
      title: l10n.notificationTitleBackground,
      body: l10n.notificationBodyBackground);
}

Map currentValueStartMap = {
  'Fajr': '5',
  'Dhuhr': '5',
  'Asr': '5',
  'Maghrib': '5',
  'Isha': '5'
};
Map currentValueEndMap = {
  'Fajr': '40',
  'Dhuhr': '40',
  'Asr': '40',
  'Maghrib': '40',
  'Isha': '40'
};

Future<void> getValueStartMap() async {
  try {
    Map newStart = await WaitAndPreWaitStoreStart().readWaitAndPreWait();
    //print('is this really a new start$newStart');
    for (String key in newStart.keys) {
      currentValueStartMap[key] = newStart[key];
    }
  } catch (e) {
    //print(e);
  }
}

Map oldValueStartMap = {};

Future<void> getValueEndMap() async {
  try {
    Map newEnd = await WaitAndPreWaitStoreEnd().readWaitAndPreWait();
    for (String key in newEnd.keys) {
      currentValueEndMap[key] = newEnd[key];
    }
  } catch (e) {
    //print(e);
  }
}

void scheduleSilence() async {
  print('am i being called rn');
  try {
    TimingsLocal localinstance =
        TimingsLocal(day: day, month: month, year: year);
    await localinstance.getTimings();
    prayers = localinstance.prayers;
    await getValueStartMap();
    await getValueEndMap();

    CreateSchedule getSchedule = CreateSchedule(
        prayers: prayers,
        prewait: currentValueStartMap,
        wait: currentValueEndMap);
    await getSchedule.createSchedule();
    scheduleStart = getSchedule.scheduleStart;
    scheduleEnd = getSchedule.scheduleEnd;
    for (int i = 0; i < 5; i++) {
      if (DateTime.parse(scheduleStart.values.toList()[i])
          .isAfter(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[i]),
            100 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            createSilence);
      }
      if (DateTime.parse(scheduleEnd.values.toList()[i])
          .isAfter(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[i]),
            1000 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            disableSilence);
      }

      if (DateTime.parse(scheduleStart.values.toList()[i])
          .isBefore(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[i])
                .add(const Duration(days: 1)),
            100 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            createSilence);
      }
      if (DateTime.parse(scheduleEnd.values.toList()[i])
          .isBefore(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[i])
                .add(const Duration(days: 1)),
            1000 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            disableSilence);
      }
    }
  } catch (e) {
    TimingsLocal localinstance =
        TimingsLocal(day: day, month: month, year: year);
    await localinstance.getTimings();
    prayers = localinstance.prayers;
    CreateSchedule getSchedule = CreateSchedule(
        prayers: prayers,
        prewait: currentValueStartMap,
        wait: currentValueEndMap);
    await getSchedule.createSchedule();
    scheduleStart = getSchedule.scheduleStart;
    scheduleEnd = getSchedule.scheduleEnd;
    for (int i = 0; i < 5; i++) {
      if (DateTime.parse(scheduleStart.values.toList()[i])
          .isAfter(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[i]),
            100 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            createSilence);
      }
      if (DateTime.parse(scheduleEnd.values.toList()[i])
          .isAfter(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[i]),
            1000 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            disableSilence);
      }

      if (DateTime.parse(scheduleStart.values.toList()[i])
          .isBefore(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[i])
                .add(const Duration(days: 1)),
            100 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            createSilence);
      }
      if (DateTime.parse(scheduleEnd.values.toList()[i])
          .isBefore(DateTime.now())) {
        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[i])
                .add(const Duration(days: 1)),
            1000 - i,
            wakeup: false,
            rescheduleOnReboot: true,
            alarmClock: true,
            allowWhileIdle: true,
            exact: true,
            disableSilence);
      }
    }
  }
}
