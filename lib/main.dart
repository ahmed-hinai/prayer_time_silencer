import 'package:flutter/material.dart';
import 'package:prayer_time_silencer/pages/home.dart';
import 'package:prayer_time_silencer/pages/loading.dart';
import 'package:prayer_time_silencer/pages/settings.dart';
import 'package:prayer_time_silencer/pages/aboutus.dart';
import 'package:prayer_time_silencer/pages/corrections.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:prayer_time_silencer/pages/languagesetting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void createSilenceBackgroundNotification() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);
  await ShortLocalNotifications().showBackgroundNotification(
      title: l10n.notificationTitleBackground,
      body: l10n.notificationBodyBackground);
}

@pragma('vm:entry-point')
void createSilence() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);
  await LocalNotifications().showNotification(
      title: l10n.notificationTitle, body: l10n.notificationBody);
  await Future.delayed(const Duration(minutes: 5));
  await MuteSystemSounds().muteSystemSounds();
}

@pragma('vm:entry-point')
void disableSilence() async {
  await LocalNotifications().cancelNotification();
  await MuteSystemSounds().enableSystemSounds();
}

const Periodic1HourSchedulingTask =
    "com.example.prayer_time_silencer.Periodic1HourSchedulingTask";

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case Periodic1HourSchedulingTask:
        try {
          switch (MyAppState.isSchedulingON) {
            case (true):
              createSilenceBackgroundNotification();
              MyAppState().scheduleSilence();
              print("$Periodic1HourSchedulingTask was executed");
              return Future.value(true);
          }
        } catch (e) {
          print(e);
          return Future.value(false);
        }
    }

    return Future.value(true);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static bool? isSchedulingON;
  Locale? _locale;

  final int day = DateTime.now().day;
  final int month = DateTime.now().month;
  final int year = DateTime.now().year;
  late var data;
  Map<String, DateTime> prayers = {};
  Map<String, String> scheduleStart = {};
  Map<String, String> scheduleEnd = {};
  bool _enabled = true;
  int _status = 0;
  final List<DateTime> _events = [];

  void getLocalStoredSchedule() async {
    try {
      Map imjustherefortheloop = await ScheduleStorageStart().readSchedule();
      Map metoo = await ScheduleStorageEnd().readSchedule();
      for (String key in imjustherefortheloop.keys) {
        setState(() {
          scheduleStart[key] = imjustherefortheloop[key];
          scheduleEnd[key] = metoo[key];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getLocalePref();
    getLocalStoredSchedule();
    getSchedulingPref();
    try {
      switch (isSchedulingON) {
        case (true):
          Workmanager().registerPeriodicTask(
            Periodic1HourSchedulingTask,
            Periodic1HourSchedulingTask,
            frequency: const Duration(hours: 2),
          );
          break;
      }
    } catch (e) {
      print(e);
    }
  }

  void setLocale(Locale value) async {
    setState(() {
      _locale = value;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      Workmanager().registerPeriodicTask(
        Periodic1HourSchedulingTask,
        Periodic1HourSchedulingTask,
        frequency: const Duration(hours: 2),
      );
    }
    if (state == AppLifecycleState.paused) {
      Workmanager().registerPeriodicTask(
        Periodic1HourSchedulingTask,
        Periodic1HourSchedulingTask,
        frequency: const Duration(hours: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ar', ''), // Arabic , no country code
        Locale('ur', '')
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const Loading(),
        '/home': (context) => const Home(),
        '/Settings': (context) => const Settings(),
        '/About us': (context) => const Aboutus(),
        '/corrections': (context) => const Corrections(),
        '/languagesetting': (context) => const LanguageSetting(),
      },
    );
  }

  Future<void> setLocalePref(value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language', value);
  }

  Future<void> getLocalePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      try {
        _locale = Locale(prefs.getString('language')!);
      } catch (e) {
        print(e);
      }
    });
  }

  Future<void> setSchedulingPref(value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('scheduling', value);
  }

  Future<void> getSchedulingPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      try {
        isSchedulingON = prefs.getBool('scheduling')!;
      } catch (e) {
        print('something wrong with setting isSchedulingON $e');
        isSchedulingON = true;
        setSchedulingPref(true);
      }
    });
  }

  void scheduleSilence() async {
    try {
      for (int i = 0; i < 5; i++) {
        if (DateTime.parse(scheduleStart.values.toList()[i])
            .isAfter(DateTime.now())) {
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleStart.values.toList()[i])
                  .subtract(const Duration(minutes: 5)),
              100 - i,
              rescheduleOnReboot: true,
              exact: true,
              createSilence);

          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleEnd.values.toList()[i]),
              1000 - i,
              rescheduleOnReboot: true,
              exact: true,
              disableSilence);

          print('is this working?${scheduleStart.values.toList()[i]}');
        }
        if (DateTime.parse(scheduleStart.values.toList()[i])
            .isBefore(DateTime.now())) {
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleStart.values.toList()[i])
                  .add(const Duration(days: 1))
                  .subtract(const Duration(minutes: 5)),
              200 - i,
              rescheduleOnReboot: true,
              exact: true,
              createSilence);

          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleEnd.values.toList()[i])
                  .add(const Duration(days: 1)),
              2000 - i,
              rescheduleOnReboot: true,
              exact: true,
              disableSilence);

          print(
              'is this working for next day?${DateTime.parse(scheduleStart.values.toList()[i]).add(const Duration(days: 1))}');
        }
      }
    } catch (e) {
      print(e);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await LocalNotifications().initialize();
  Workmanager().initialize(
    callbackDispatcher, // The top level function, aka callbackDispatche//
  );

  runApp(const MyApp());
}
