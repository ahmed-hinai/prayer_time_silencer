import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:prayer_time_silencer/pages/home.dart';
import 'package:prayer_time_silencer/pages/loading.dart';
import 'package:prayer_time_silencer/pages/settings.dart';
import 'package:prayer_time_silencer/pages/aboutus.dart';
import 'package:prayer_time_silencer/pages/corrections.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:prayer_time_silencer/pages/languagesetting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/wait_and_prewait_store.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:workmanager/workmanager.dart';

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

  int day = DateTime.now().day;
  int month = DateTime.now().month;
  int year = DateTime.now().year;
  Map<String, DateTime> prayers = {};
  Map<String, String> scheduleStart = {};
  Map<String, String> scheduleEnd = {};

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
      //print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getLocalePref();
    getLocalStoredSchedule();
    getSchedulingPref();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setLocale(Locale value) async {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
        //print(e);
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
        //print('something wrong with setting isSchedulingON $e');
        isSchedulingON = true;
        setSchedulingPref(true);
      }
    });
  }
}

const silencePeriodicTask =
    "org.ahmedhinai.prayer_time_silencer.silencePeriodicTask";
Workmanager workmanager = Workmanager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await LocalNotifications().initialize();

  runApp(const MyApp());
  await initializeService();
}

Future<void> initializeService() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);

  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'foreground_silence', // id
    'FOREGROUND SILENCE SERVICE', // title
    description:
        'This channel is used for when the app is running in the background.', // description
    importance: Importance.low,

    showBadge: false,
    // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  final prefs = await SharedPreferences.getInstance();
  bool isItOn;
  try {
    isItOn = prefs.getBool('scheduling')!;
  } catch (e) {
    isItOn = true;
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: isItOn ? onStart : onDoNothing,

      // auto start service

      autoStart: isItOn ? true : false,
      isForegroundMode: true,
      notificationChannelId: 'foreground_silence',
      initialNotificationTitle: l10n.notificationTitleBackground,
      initialNotificationContent: l10n.notificationBodyBackground,
      foregroundServiceNotificationId: 888,
      autoStartOnBoot: isItOn ? true : false,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return false;
}

void onDoNothing(ServiceInstance service) async {}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      await workmanager.initialize(callbackDispatcher, isInDebugMode: false);
      await workmanager.registerPeriodicTask("1", silencePeriodicTask,
          existingWorkPolicy: ExistingWorkPolicy.replace,
          frequency: Duration(hours: 5),
          initialDelay: Duration(seconds: 60));

      LocalNotifications instance = LocalNotifications();
      instance.showNotificationBackground(
        title: l10n.notificationTitleBackground,
        body: l10n.notificationBodyBackground,
      );
    }
  }
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await scheduleSilence();
    print(
        "Native called background task: $silencePeriodicTask"); //simpleTask will be emitted here.
    return Future.value(true);
  });
}

int day = DateTime.now().day;
int month = DateTime.now().month;
int year = DateTime.now().year;
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

@pragma('vm:entry-point')
Future<void> scheduleSilence() async {
  int day = DateTime.now().day;
  int month = DateTime.now().month;
  int year = DateTime.now().year;
  try {
    print('scheduleSilence called');
    print(day);
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
    try {
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
      print(e);
    }
  } catch (e) {
    print('Failed to scheudle Silence times.');
    LocalNotifications instance = LocalNotifications();
    instance.showNotificationNoData(
        title: 'no data', body: 'App couldnt retrieve local data');
  }
}
