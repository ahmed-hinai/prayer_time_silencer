import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:prayer_time_silencer/services/get_device_location.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  void initState() {
    super.initState();
    initPlatformState();
  }

  static Future<void> pop({bool? animated}) async {
    await SystemChannels.platform
        .invokeMethod<void>('SystemNavigator.pop', animated);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            forceAlarmManager: true,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      scheduleSilence();
      // <-- Event handler
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      setState(() {
        _events.insert(0, new DateTime.now());
      });
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
  }

  late double latitude;
  late double longitude;
  final int day = DateTime.now().day;
  final int month = DateTime.now().month;
  final int year = DateTime.now().year;
  var icon = Icon(Icons.notifications);
  bool gpsvisible = true;
  bool schedulevisible = false;
  bool confirmvisible = false;
  bool timingsvisible = true;

  Map<String, dynamic> oldPrayers = {
    'Fajr': DateFormat.Hm().format(DateTime.now()),
    'Dhuhr': DateFormat.Hm().format(DateTime.now()),
    'Asr': DateFormat.Hm().format(DateTime.now()),
    'Maghrib': DateFormat.Hm().format(DateTime.now()),
    'Isha': DateFormat.Hm().format(DateTime.now())
  };
  late var data;
  Map<String, DateTime> prayers = {};
  Map<String, String> schedule = {};
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('back button pressed');
        if (ModalRoute.of(context)?.settings.name == '/home') {
          pop();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        drawer: Drawer(
          backgroundColor: Colors.blue[900],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: TextField(
                  onSubmitted: ((text) async {
                    GetLocationFromInput newLocation =
                        GetLocationFromInput(location: text);
                    await newLocation.getLocationFromUserInput();
                    latitude = newLocation.latitude;
                    longitude = newLocation.longitude;
                    Timings instance = Timings(
                        lat: latitude,
                        long: longitude,
                        day: day,
                        month: month,
                        year: year);
                    await instance.getTimings();
                    prayers = instance.prayers;
                    setState(() {
                      for (String key in oldPrayers.keys) {
                        oldPrayers[key] = DateFormat.Hm().format(prayers[key]!);
                      }
                    });
                    ;
                  }),
                  onChanged: (value) {
                    print('First text field: $value');
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    hintText: 'Enter location',
                  ),
                ),
              )
            ],
          ),
        ),
        appBar: AppBar(
          elevation: 3.0,
          title: Text("Get Prayer timings"),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          actions: [
            Switch(value: _enabled, onChanged: _onClickEnable),
            PopupMenuButton<String>(
              itemBuilder: (BuildContext context) {
                return {'aboutus', 'settings'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 1));
                      await Navigator.pushNamed(context, '/$choice');
                    },
                  );
                }).toList();
              },
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(55.0, 8.0, 55.0, 8.0),
              child: AnimationLimiter(
                child: Visibility(
                  visible: timingsvisible,
                  child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: prayers.length,
                      itemBuilder: ((context, index) {
                        return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(microseconds: 375),
                            child: SlideAnimation(
                                child: FadeInAnimation(
                                    child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Card(
                                        color: Colors.blue[900],
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(70.0)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              '${oldPrayers.keys.toList()[index]}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Card(
                                        color: Colors.blue[900],
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(70.0)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              '${oldPrayers.values.toList()[index]}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ))));
                      })),
                ),
              ),
            ),
            Visibility(
              visible: gpsvisible,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 230.0),
                child: IconButton(
                  color: Colors.white,
                  onPressed: () async {
                    GetLocationFromGPS newLocation = GetLocationFromGPS();
                    await newLocation.getLocationFromGPS();
                    latitude = newLocation.latitude;
                    longitude = newLocation.longitude;
                    print('is this correct? $day');
                    Timings instance = Timings(
                        lat: latitude,
                        long: longitude,
                        day: day,
                        month: month,
                        year: year);
                    await instance.getTimings();
                    prayers = instance.prayers;
                    CreateSchedule getSchedule =
                        CreateSchedule(prayers: prayers);
                    await getSchedule.createSchedule();
                    schedule = getSchedule.schedule;
                    setState(() {
                      for (String key in oldPrayers.keys) {
                        oldPrayers[key] = DateFormat.Hm().format(prayers[key]!);
                        gpsvisible = false;
                        schedulevisible = true;
                      }
                    });
                    ;
                  },
                  icon: Icon(Icons.location_on),
                  iconSize: 80,
                  tooltip: 'gets device location',
                ),
              ),
            ),
            Visibility(
              maintainAnimation: true,
              maintainState: true,
              visible: schedulevisible,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 50.0),
                child: Card(
                  color: Colors.grey[800],
                  child: Row(
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Schedule Times of Silence.',
                            style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Icon(Icons.check,
                                color: Colors.white, size: 30.0),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            elevation: 20.0,
                          ),
                          onPressed: () async {
                            bool isGranted =
                                (await PermissionHandler.permissionsGranted)!;
                            scheduleSilence();
                            if (!isGranted) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                        actions: [
                                          TextButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await PermissionHandler
                                                    .openDoNotDisturbSetting();
                                                await Future.delayed(
                                                    Duration(seconds: 5));

                                                scheduleSilence();
                                              },
                                              child: const Text('ok'))
                                        ],
                                        title: Text('Access required'),
                                        content: Text(
                                            'The app requires disturb access to function properly'),
                                      ));
                              // Opens the Do Not Disturb Access settings to grant the access

                            }

                            setState(() {
                              schedulevisible = false;
                              timingsvisible = false;
                              confirmvisible = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
                visible: confirmvisible,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28.0, 0.0, 28.0, 250.0),
                  child: Column(
                    children: [
                      Card(
                        color: Colors.blue[900],
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Text('Silence Times Have been Scheduled.',
                              style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 40.0,
            ),
          ]),
        ),
      ),
    );
  }

  @pragma('vm:entry-point')
  static void createSilence() async {
    MuteSystemSounds().muteSystemSounds();
  }

  @pragma('vm:entry-point')
  static void disableSilence1() async {
    MuteSystemSounds().enableSystemSounds();
    LocalNotifications().cancelNotification1();
  }

  @pragma('vm:entry-point')
  static void disableSilence2() async {
    MuteSystemSounds().enableSystemSounds();
    LocalNotifications().cancelNotification2();
  }

  @pragma('vm:entry-point')
  static void disableSilence3() async {
    MuteSystemSounds().enableSystemSounds();
    LocalNotifications().cancelNotification3();
  }

  @pragma('vm:entry-point')
  static void disableSilence4() async {
    MuteSystemSounds().enableSystemSounds();
    LocalNotifications().cancelNotification4();
  }

  @pragma('vm:entry-point')
  static void disableSilence5() async {
    MuteSystemSounds().enableSystemSounds();
    LocalNotifications().cancelNotification5();
  }

  void scheduleSilence() async {
    int id = 0;

    try {
      if (DateTime.parse(schedule.keys.toList()[0]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 9,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[0]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[0]),
            99,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[0]),
            999,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence1);

        print('is this working?${schedule.keys.toList()[0]}');
      }

      if (DateTime.parse(schedule.keys.toList()[1]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 1,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[1]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[1]),
            11,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);
        print('is this working?${schedule.keys.toList()[1]}');

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[1]),
            111,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence2);
      }

      if (DateTime.parse(schedule.keys.toList()[2]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 2,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[2]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[2]),
            22,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[2]),
            222,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence3);
        print('is this working?${schedule.keys.toList()[2]}');
      }

      if (DateTime.parse(schedule.keys.toList()[3]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 3,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[3]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[3]),
            33,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[3]),
            333,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence4);
        print('is this working?${schedule.keys.toList()[3]}');
      }

      if (DateTime.parse(schedule.keys.toList()[4]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 4,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[4]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[4]),
            44,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[4]),
            444,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence5);
        print('is this working?${schedule.keys.toList()[4]}');
      } else {}
    } catch (e) {
      TimingsLocal localinstance =
          TimingsLocal(day: day, month: month, year: year);
      await localinstance.getTimings();
      prayers = localinstance.prayers;
      CreateSchedule getSchedule = CreateSchedule(prayers: prayers);
      await getSchedule.createSchedule();
      schedule = getSchedule.schedule;
      if (DateTime.parse(schedule.keys.toList()[0]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 9,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[0]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[0]),
            99,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[0]),
            999,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence1);

        print('is this working?${schedule.keys.toList()[0]}');
      }

      if (DateTime.parse(schedule.keys.toList()[1]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 1,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[1]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[1]),
            11,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);
        print('is this working?${schedule.keys.toList()[1]}');

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[1]),
            111,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence2);
      }

      if (DateTime.parse(schedule.keys.toList()[2]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 2,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[2]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[2]),
            22,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[2]),
            222,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence3);
        print('is this working?${schedule.keys.toList()[2]}');
      }

      if (DateTime.parse(schedule.keys.toList()[3]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 3,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[3]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[3]),
            33,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[3]),
            333,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence4);
        print('is this working?${schedule.keys.toList()[3]}');
      }

      if (DateTime.parse(schedule.keys.toList()[4]).isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        notifySilence.showNotification(
            id: 4,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(schedule.keys.toList()[4]));

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.keys.toList()[4]),
            44,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        AndroidAlarmManager.oneShotAt(
            DateTime.parse(schedule.values.toList()[4]),
            444,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence5);
        print('is this working?${schedule.keys.toList()[4]}');

        print(e);
      }
    }
  }
}
