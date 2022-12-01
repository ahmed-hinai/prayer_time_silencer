import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_silencer/services/get_device_location.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:sound_mode/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late double latitude;
  late double longitude;
  final int day = DateTime.now().day;
  final int month = DateTime.now().month;
  final int year = DateTime.now().year;
  var icon = Icon(Icons.notifications);

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
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        title: Text("Get Prayer timings"),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return {'About us', 'Settings'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                color: Colors.white,
                onPressed: () async {
                  await MuteSystemSounds().muteSystemSounds();
                  setState(() {
                    icon = Icon(Icons.notifications_off);
                  });
                },
                icon: icon,
                iconSize: 50.0,
                tooltip: 'Puts your phone to silent mode',
              ),
              IconButton(
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
                  CreateSchedule getSchedule = CreateSchedule(prayers: prayers);
                  await getSchedule.createSchedule();
                  schedule = getSchedule.schedule;
                  setState(() {
                    for (String key in oldPrayers.keys) {
                      oldPrayers[key] = DateFormat.Hm().format(prayers[key]!);
                    }
                  });
                  ;
                },
                icon: Icon(Icons.location_on),
                iconSize: 50.0,
                tooltip: 'gets device location',
              ),
              IconButton(
                color: Colors.white,
                onPressed: () async {
                  bool isGranted =
                      (await PermissionHandler.permissionsGranted)!;
                  if (!isGranted) {
                    // Opens the Do Not Disturb Access settings to grant the access
                    await PermissionHandler.openDoNotDisturbSetting();
                  }
                  scheduleSilence();
                },
                icon: Icon(Icons.access_time),
                iconSize: 50.0,
                tooltip: 'gets device location',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48.0, 18.0, 48.0, 18.0),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(55.0, 8.0, 55.0, 8.0),
            child: AnimationLimiter(
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
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(70.0)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          '${oldPrayers.keys.toList()[index]}',
                                          style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(70.0)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          '${oldPrayers.values.toList()[index]}',
                                          style: TextStyle(
                                              color: Colors.grey[800],
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
          SizedBox(
            height: 40.0,
          ),
        ]),
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
      print(e);
    }
  }
}
