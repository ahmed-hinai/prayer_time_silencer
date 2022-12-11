import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:prayer_time_silencer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_silencer/services/get_device_location.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:prayer_time_silencer/services/corrections_store.dart';
import 'package:prayer_time_silencer/services/wait_and_prewait_store.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_settings/open_settings.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.window.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  final l10n = await AppLocalizations.delegate.load(locale);
  LocalNotifications instance = LocalNotifications();
  instance.showNotificationBackground(
      title: l10n.notificationTitleBackground,
      body: l10n.notificationBodyBackground);
  await MuteSystemSounds().enableSystemSounds();
}

const Periodic6HourSchedulingTask =
    "org.ahmedhinai.prayer_time_silencer.Periodic6HourSchedulingTask";

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case Periodic6HourSchedulingTask:
        try {
          switch (MyAppState.isSchedulingON) {
            case (true):
              // createSilenceBackgroundNotification();
              _HomeState().scheduleSilence();
              //print("$Periodic1HourSchedulingTask was executed");
              return Future.value(true);
          }
        } catch (e) {
          //print(e);
          return Future.value(false);
        }
    }

    return Future.value(true);
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();

  static of(BuildContext context) {}
}

class _HomeState extends State<Home> {
  final bool _enabled = true;
  final int _status = 0;
  final int _currentValueStart = 5;
  final int _currentValueEnd = 40;
  final List<DateTime> _events = [];
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

  void getValueStartMap() async {
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

  void getValueEndMap() async {
    try {
      Map newEnd = await WaitAndPreWaitStoreEnd().readWaitAndPreWait();
      for (String key in newEnd.keys) {
        currentValueEndMap[key] = newEnd[key];
      }
    } catch (e) {
      //print(e);
    }
  }

  Map oldValueEndMap = {};
  @override
  void initState() {
    super.initState();
    // initPlatformState();
    getValueStartMap();
    getValueEndMap();
    Future.delayed(Duration.zero, () {
      secondComings();
    });
  }

  static Future<void> pop({bool? animated}) async {
    await SystemChannels.platform
        .invokeMethod<void>('SystemNavigator.pop', animated);
  }

  void secondComings() async {
    try {
      await getLocaltimings();
      if (scheduleStart.values.toList().length > 2) {
        setState(() {
          gpsvisible = false;
          timingsvisible = false;
          timingsvisible2 = true;
          schedulevisible = false;
          confirmvisible = true;
        });

        scheduleSilence();
        Workmanager().registerPeriodicTask(
          Periodic6HourSchedulingTask,
          Periodic6HourSchedulingTask,
          frequency: const Duration(hours: 6),
        );
      } else {
        setState(() {
          gpsvisible = true;
          timingsvisible = false;
          timingsvisible2 = false;
          schedulevisible = false;
          confirmvisible = false;
        });
      }
    } catch (e) {
      print('hello? $e');
      setState(() {
        gpsvisible = true;
        timingsvisible = false;
        timingsvisible2 = false;
        schedulevisible = false;
        confirmvisible = false;
      });
    }
  }

  late var timeSelected;

  double latitude = 0;
  double longitude = 0;
  static bool? weHaveTimings;
  final int day = DateTime.now().day;
  final int month = DateTime.now().month;
  final int year = DateTime.now().year;
  var icon = const Icon(Icons.notifications);
  bool gpsvisible = false;
  bool timingsvisible = false;
  bool timingsvisible2 = false;
  bool schedulevisible = false;
  bool confirmvisible = false;
  List<bool> selections = [true, false, false, false, false];
  static String notificationTitle = "Prayer Time Silencer";
  static String notificationBody = "Your device will be silenced in 5 minutes.";
  Map<String, dynamic> oldPrayers = {
    'Fajr': '',
    'Dhuhr': '',
    'Asr': '',
    'Maghrib': '',
    'Isha': ''
  };

  List localizedPrayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  late var data;
  static Map<String, DateTime> prayers = {};
  Map<String, String> scheduleStart = {};
  Map<String, String> scheduleEnd = {};

  Future<void> getLocaltimings() async {
    try {
      TimingsLocal localinstance =
          TimingsLocal(day: day, month: month, year: year);
      await localinstance.getTimings();
      prayers = localinstance.prayers;
      for (var key in prayers.keys) {
        oldPrayers[key] = DateFormat.Hm().format(prayers[key]!);
      }
      CreateSchedule getSchedule = CreateSchedule(
          prayers: prayers,
          prewait: currentValueStartMap,
          wait: currentValueEndMap);
      await getSchedule.createSchedule();
      scheduleStart = getSchedule.scheduleStart;
      scheduleEnd = getSchedule.scheduleEnd;
      setState(() {
        weHaveTimings = true;
      });
    } catch (e) {
      //print(e);
      setState(() {
        weHaveTimings = false;
      });
    }
  }

  int getValueStart(selections) {
    for (int i = 0; i < 5; i++) {
      switch (selections[i]) {
        case true:
          return int.parse(currentValueStartMap.values.toList()[i]);
      }
    }
    return 0;
  }

  int getValueEnd(selections) {
    for (int i = 0; i < 5; i++) {
      switch (selections[i]) {
        case true:
          return int.parse(currentValueEndMap.values.toList()[i]);
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //print('back button pressed');
        if (ModalRoute.of(context)?.settings.name == '/home') {
          pop();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          backgroundColor: const Color.fromARGB(255, 7, 64, 111),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    AppLocalizations.of(context)!.enterToRetrievePrayerTimes,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: TextField(
                    onSubmitted: ((text) async {
                      notificationTitle =
                          AppLocalizations.of(context)!.doNotDistrubTitle;
                      notificationBody =
                          AppLocalizations.of(context)!.doNotDistrubBody;
                      Navigator.pop(context);

                      try {
                        GetLocationFromInput newLocation =
                            GetLocationFromInput(location: text);
                        await newLocation.getLocationFromUserInput();
                        latitude = newLocation.latitude;
                        longitude = newLocation.longitude;
                        var connectivityResult =
                            await (Connectivity().checkConnectivity());
                        if (connectivityResult == ConnectivityResult.none) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .networkFailMessage)));
                        }
                        CorrectionsStorage storedCorrections =
                            CorrectionsStorage();
                        var newCorrections =
                            await storedCorrections.readCorrections();
                        Timings instance = Timings(
                            lat: latitude,
                            long: longitude,
                            day: day,
                            month: month,
                            year: year,
                            corrections: newCorrections);
                        await instance.getTimings();
                        prayers = instance.prayers;
                        CreateSchedule getSchedule = CreateSchedule(
                            prayers: prayers,
                            prewait: currentValueStartMap,
                            wait: currentValueEndMap);
                        await getSchedule.createSchedule();
                        scheduleStart = getSchedule.scheduleStart;
                        scheduleEnd = getSchedule.scheduleEnd;
                        setState(() {
                          for (String key in oldPrayers.keys) {
                            oldPrayers[key] =
                                DateFormat.Hm().format(prayers[key]!);
                            timingsvisible2 = false;
                            timingsvisible = true;
                            schedulevisible = true;
                            confirmvisible = false;
                            gpsvisible = false;
                          }
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.failedMessage)));
                      }
                    }),
                    onChanged: (value) {
                      //print('First text field: $value');
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                      hintText: AppLocalizations.of(context)!.enterLocation,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        appBar: AppBar(
          elevation: 1.0,
          title: const Text(""),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          actions: [
            PopupMenuButton<String>(
              itemBuilder: (BuildContext context) {
                return {
                  AppLocalizations.of(context)!.settings,
                  AppLocalizations.of(context)!.aboutUs
                }.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 1));
                      choice == AppLocalizations.of(context)!.aboutUs
                          ? Navigator.pushNamed(context, '/About us')
                          : choice == AppLocalizations.of(context)!.settings
                              ? Navigator.pushNamed(context, '/Settings')
                              : () {};
                    },
                  );
                }).toList();
              },
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18.0, 1.0, 18.0, 1.0),
                  child: Visibility(
                      visible: timingsvisible,
                      child: Transform.scale(
                        scale: .9,
                        child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: prayers.length,
                            itemBuilder: ((context, index) {
                              return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return ToggleButtons(
                                        borderWidth: 3.0,
                                        selectedBorderColor: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(70),
                                        constraints: BoxConstraints.expand(
                                            width: constraints.maxWidth / 1.03),
                                        isSelected: [selections[index]],
                                        onPressed: (indexx) {
                                          setState(() {
                                            for (int i = 0;
                                                i < selections.length;
                                                i++) {
                                              selections[i] = i == index;
                                              // selections[index] = !selections[index];
                                            }
                                          });
                                        },
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 8,
                                                child: Card(
                                                  color: const Color.fromARGB(
                                                      255, 7, 64, 111),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              70.0)),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .fromLTRB(
                                                        8.0, 1.0, 8.0, 1.0),
                                                    child: Center(
                                                      child: Text(
                                                        index == 0
                                                            ? AppLocalizations
                                                                    .of(
                                                                        context)!
                                                                .fajr
                                                            : index == 1
                                                                ? AppLocalizations.of(
                                                                        context)!
                                                                    .dhuhr
                                                                : index == 2
                                                                    ? AppLocalizations.of(
                                                                            context)!
                                                                        .asr
                                                                    : index == 3
                                                                        ? AppLocalizations.of(context)!
                                                                            .maghrib
                                                                        : index ==
                                                                                4
                                                                            ? AppLocalizations.of(context)!.isha
                                                                            : '',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 12,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Card(
                                                        color: Colors.grey[600],
                                                        child: Center(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .fromLTRB(
                                                                    8.0,
                                                                    1.0,
                                                                    8.0,
                                                                    1.0),
                                                            child: Text(
                                                              DateFormat.Hm().format(
                                                                  DateTime.parse(
                                                                      scheduleStart
                                                                          .values
                                                                          .toList()[index])),
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      16.0,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Card(
                                                        color: Colors.grey[600],
                                                        child: Center(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .fromLTRB(
                                                                    8.0,
                                                                    1.0,
                                                                    8.0,
                                                                    1.0),
                                                            child: Text(
                                                                DateFormat.Hm().format(
                                                                    DateTime.parse(scheduleEnd
                                                                            .values
                                                                            .toList()[
                                                                        index])),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        16.0,
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 8,
                                                child: Card(
                                                  color: const Color.fromARGB(
                                                      255, 7, 64, 111),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              70.0)),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Center(
                                                      child: Text(
                                                        '${oldPrayers.values.toList()[index]}',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      );
                                    })),
                                  ]);
                            })),
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18.0, 1.0, 18.0, 1.0),
                  child: Visibility(
                      visible: timingsvisible2,
                      child: Transform.scale(
                        scale: .9,
                        child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: prayers.length,
                            itemBuilder: ((context, index) {
                              return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(child: LayoutBuilder(
                                        builder: (context, constraints) {
                                      return ToggleButtons(
                                        borderWidth: 3.0,
                                        selectedBorderColor: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(70),
                                        constraints: BoxConstraints.expand(
                                            width: constraints.maxWidth / 1.03),
                                        isSelected: const [false],
                                        onPressed: (indexx) {
                                          setState((() => null));
                                        },
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 8,
                                                child: Card(
                                                  color: const Color.fromARGB(
                                                      255, 7, 64, 111),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              70.0)),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .fromLTRB(
                                                        8.0, 1.0, 8.0, 1.0),
                                                    child: Center(
                                                      child: Text(
                                                        index == 0
                                                            ? AppLocalizations
                                                                    .of(
                                                                        context)!
                                                                .fajr
                                                            : index == 1
                                                                ? AppLocalizations.of(
                                                                        context)!
                                                                    .dhuhr
                                                                : index == 2
                                                                    ? AppLocalizations.of(
                                                                            context)!
                                                                        .asr
                                                                    : index == 3
                                                                        ? AppLocalizations.of(context)!
                                                                            .maghrib
                                                                        : index ==
                                                                                4
                                                                            ? AppLocalizations.of(context)!.isha
                                                                            : '',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 12,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Card(
                                                        color: Colors.grey[600],
                                                        child: Center(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .fromLTRB(
                                                                    8.0,
                                                                    1.0,
                                                                    8.0,
                                                                    1.0),
                                                            child: Text(
                                                              DateFormat.Hm().format(
                                                                  DateTime.parse(
                                                                      scheduleStart
                                                                          .values
                                                                          .toList()[index])),
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      16.0,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Card(
                                                        color: Colors.grey[600],
                                                        child: Center(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .fromLTRB(
                                                                    8.0,
                                                                    1.0,
                                                                    8.0,
                                                                    1.0),
                                                            child: Text(
                                                                DateFormat.Hm().format(
                                                                    DateTime.parse(scheduleEnd
                                                                            .values
                                                                            .toList()[
                                                                        index])),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        16.0,
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 8,
                                                child: Card(
                                                  color: const Color.fromARGB(
                                                      255, 7, 64, 111),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              70.0)),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Center(
                                                      child: Text(
                                                        '${oldPrayers.values.toList()[index]}',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      );
                                    })),
                                  ]);
                            })),
                      )),
                ),
                Visibility(
                  visible: gpsvisible,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 200.0, 8.0, 230.0),
                    child: Column(
                      children: [
                        // Text(
                        //   AppLocalizations.of(context)!.beginHere,
                        //   style: const TextStyle(
                        //       color: Colors.white, fontSize: 18.0),
                        // ),
                        // const Icon(
                        //   Icons.arrow_downward,
                        //   color: Colors.white,
                        //   size: 30.0,
                        // ),
                        IconButton(
                          color: const Color.fromARGB(255, 7, 64, 111),
                          onPressed: () async {
                            notificationTitle =
                                AppLocalizations.of(context)!.doNotDistrubTitle;
                            notificationBody =
                                AppLocalizations.of(context)!.doNotDistrubBody;
                            GetLocationFromGPS newLocation =
                                GetLocationFromGPS();
                            var connectivityResult =
                                await (Connectivity().checkConnectivity());
                            if (connectivityResult == ConnectivityResult.none) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .networkFailMessage)));
                            }

                            try {
                              await newLocation.getLocationFromGPS();
                              latitude = newLocation.latitude;
                              longitude = newLocation.longitude;
                              CorrectionsStorage storedCorrections =
                                  CorrectionsStorage();
                              var newCorrections =
                                  await storedCorrections.readCorrections();
                              //print('is this correct? $day');
                              Timings instance = Timings(
                                  lat: latitude,
                                  long: longitude,
                                  day: day,
                                  month: month,
                                  year: year,
                                  corrections: newCorrections);
                              await instance.getTimings();
                              prayers = instance.prayers;
                              CreateSchedule getSchedule = CreateSchedule(
                                  prayers: prayers,
                                  prewait: currentValueStartMap,
                                  wait: currentValueEndMap);
                              await getSchedule.createSchedule();
                              scheduleStart = getSchedule.scheduleStart;
                              scheduleEnd = getSchedule.scheduleEnd;

                              setState(() {
                                for (String key in oldPrayers.keys) {
                                  oldPrayers[key] =
                                      DateFormat.Hm().format(prayers[key]!);
                                  gpsvisible = false;
                                  timingsvisible = true;
                                  schedulevisible = true;
                                }
                              });
                            } catch (e) {
                              //print(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .failedMessage)));
                            }
                          },
                          icon: const Icon(Icons.location_on),
                          iconSize: 180,
                          tooltip:
                              AppLocalizations.of(context)!.locationTooltip,
                          style: IconButton.styleFrom(elevation: 50),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  maintainAnimation: true,
                  maintainState: true,
                  visible: schedulevisible,
                  child: Transform.scale(
                    scale: .9,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18.0, 1.0, 18.0, 1.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Card(
                                color: Colors.grey[600],
                                child: Container(
                                  child: NumberPicker(
                                    itemWidth: 168.0,
                                    textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    value: getValueStart(selections),
                                    minValue: 0,
                                    maxValue: 20,
                                    onChanged: (value) => setState(() {
                                      for (String key in scheduleStart.keys) {
                                        switch (selections[scheduleStart.keys
                                            .toList()
                                            .indexOf(key)]) {
                                          case true:
                                            oldValueStartMap[key] =
                                                currentValueStartMap[key];
                                            currentValueStartMap[key] =
                                                value.toString();
                                            scheduleStart[key] = DateTime.parse(
                                                    scheduleStart[key]
                                                        .toString())
                                                .subtract(Duration(
                                                    minutes: int.parse(
                                                        oldValueStartMap[key])))
                                                .add(Duration(
                                                    minutes: int.parse(
                                                        currentValueStartMap[
                                                            key])))
                                                .toString();
                                            break;
                                          default:
                                        }
                                      }
                                      WaitAndPreWaitStoreStart()
                                          .writeWaitAndPreWait(
                                              currentValueStartMap);
                                    }),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Card(
                                color: Colors.grey[600],
                                child: NumberPicker(
                                  itemWidth: 168.0,
                                  textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  value: getValueEnd(selections),
                                  minValue: 20,
                                  maxValue: 60,
                                  onChanged: (value) => setState(() {
                                    for (String key in scheduleEnd.keys) {
                                      switch (selections[scheduleEnd.keys
                                          .toList()
                                          .indexOf(key)]) {
                                        case true:
                                          oldValueEndMap[key] =
                                              currentValueEndMap[key];
                                          currentValueEndMap[key] =
                                              value.toString();
                                          scheduleEnd[key] = DateTime.parse(
                                                  scheduleEnd[key].toString())
                                              .subtract(Duration(
                                                  minutes: int.parse(
                                                      oldValueEndMap[key])))
                                              .add(Duration(
                                                  minutes: int.parse(
                                                      currentValueEndMap[key])))
                                              .toString();
                                          break;
                                        default:
                                      }
                                    }
                                    WaitAndPreWaitStoreEnd()
                                        .writeWaitAndPreWait(
                                            currentValueEndMap);
                                  }),
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
                Visibility(
                  maintainAnimation: true,
                  maintainState: true,
                  visible: schedulevisible,
                  child: Transform.scale(
                    scale: .9,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18.0, 0.0, 18.0, 0.0),
                      child: Row(children: [
                        Expanded(
                          child: Card(
                              color: Colors.grey[600],
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    18.0, 8.0, 18.0, 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.startSchedule,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              )),
                        ),
                        Expanded(
                          child: Card(
                            color: Colors.grey[600],
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  18.0, 8.0, 18.0, 8.0),
                              child: Text(
                                AppLocalizations.of(context)!.endSchedule,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                Visibility(
                  maintainAnimation: true,
                  maintainState: true,
                  visible: schedulevisible,
                  child: Transform.scale(
                    scale: .9,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
                      child: Card(
                        color: Colors.grey[800],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Text(
                                  AppLocalizations.of(context)!.confirmSchedule,
                                  style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 7, 64, 111),
                                  elevation: 20.0,
                                ),
                                onPressed: () async {
                                  bool isGranted = (await PermissionHandler
                                      .permissionsGranted)!;
                                  Permission.manageExternalStorage.request();

                                  if (isGranted) {
                                    setState(() {
                                      switch (MyAppState.isSchedulingON) {
                                        case (true):
                                          schedulevisible = false;
                                          timingsvisible = false;
                                          timingsvisible2 = true;
                                          confirmvisible = true;
                                          scheduleSilence();
                                          Workmanager().registerPeriodicTask(
                                            Periodic6HourSchedulingTask,
                                            Periodic6HourSchedulingTask,
                                            frequency: const Duration(hours: 6),
                                          );
                                          break;
                                        case (false):
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .schedulingIsOff)));
                                      }
                                    });
                                  }

                                  if (!isGranted) {
                                    showDialog(
                                        barrierColor: Colors.grey[800],
                                        context: context,
                                        builder: (BuildContext context) =>
                                            AlertDialog(
                                              backgroundColor: Colors.grey[800],
                                              actions: [
                                                TextButton(
                                                    onPressed: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                      await Permission
                                                          .accessNotificationPolicy
                                                          .request();
                                                      await Future.delayed(
                                                          const Duration(
                                                              seconds: 2));
                                                      OpenSettings
                                                          .openVoiceControllDoNotDisturbModeSetting();
                                                    },
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .ok))
                                              ],
                                              title: Text(
                                                AppLocalizations.of(context)!
                                                    .doNotDistrubTitle,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              content: Text(
                                                  AppLocalizations.of(context)!
                                                      .doNotDistrubBody,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            ));
                                    // Opens the Do Not Disturb Access settings to grant the access

                                  }
                                },
                                child: const Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(0.0, 48.0, 0.0, 48.0),
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 30.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                    visible: schedulevisible,
                    child: Transform.scale(
                      scale: .9,
                      child: SafeArea(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700]),
                          onPressed: (() async {
                            dynamic result = await Navigator.pushNamed(
                                context, '/corrections',
                                arguments: {
                                  'prayers': prayers,
                                  'latitude': latitude,
                                  'longitude': longitude,
                                  'day': day,
                                  'month': month,
                                  'year': year
                                });

                            Map correctedPrayers = {};
                            correctedPrayers['Fajr'] =
                                result['prayers']['Fajr'];
                            correctedPrayers['Dhuhr'] =
                                result['prayers']['Dhuhr'];
                            correctedPrayers['Asr'] = result['prayers']['Asr'];
                            correctedPrayers['Maghrib'] =
                                result['prayers']['Maghrib'];
                            correctedPrayers['Isha'] =
                                result['prayers']['Isha'];
                            CreateSchedule getNewSchedule = CreateSchedule(
                                prayers: correctedPrayers,
                                prewait: currentValueStartMap,
                                wait: currentValueEndMap);
                            await getNewSchedule.createSchedule();

                            setState(() {
                              oldPrayers['Fajr'] = DateFormat.Hm()
                                  .format(result['prayers']['Fajr']);
                              oldPrayers['Dhuhr'] = DateFormat.Hm()
                                  .format(result['prayers']['Dhuhr']);
                              oldPrayers['Asr'] = DateFormat.Hm()
                                  .format(result['prayers']['Asr']);
                              oldPrayers['Maghrib'] = DateFormat.Hm()
                                  .format(result['prayers']['Maghrib']);
                              oldPrayers['Isha'] = DateFormat.Hm()
                                  .format(result['prayers']['Isha']);

                              for (String key in scheduleStart.keys) {
                                scheduleStart[key] =
                                    getNewSchedule.scheduleStart[key]!;
                                scheduleEnd[key] =
                                    getNewSchedule.scheduleEnd[key]!;
                              }
                            });
                          }),
                          child:
                              Text(AppLocalizations.of(context)!.corrections),
                        ),
                      ),
                    )),
                Visibility(
                    visible: confirmvisible,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(60, 0, 60, 8),
                      child: Column(
                        children: [
                          Card(
                            color: const Color.fromARGB(255, 7, 64, 111),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(58, 58, 58, 58),
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .confirmationMessage,
                                  style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Visibility(
                          visible: confirmvisible,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Tooltip(
                              message:
                                  AppLocalizations.of(context)!.editTooltip,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 7, 64, 111)),
                                onPressed: () async {
                                  setState(() {
                                    gpsvisible = false;
                                    schedulevisible = true;
                                    confirmvisible = false;
                                    timingsvisible2 = false;
                                    timingsvisible = true;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.grey[900],
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Visibility(
                          visible: confirmvisible,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Tooltip(
                              message:
                                  AppLocalizations.of(context)!.locationTooltip,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 7, 64, 111)),
                                onPressed: () async {
                                  GetLocationFromGPS newLocation =
                                      GetLocationFromGPS();
                                  var connectivityResult = await (Connectivity()
                                      .checkConnectivity());
                                  if (connectivityResult ==
                                      ConnectivityResult.none) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                AppLocalizations.of(context)!
                                                    .networkFailMessage)));
                                  }

                                  try {
                                    await newLocation.getLocationFromGPS();
                                    latitude = newLocation.latitude;
                                    longitude = newLocation.longitude;
                                    CorrectionsStorage storedCorrections =
                                        CorrectionsStorage();
                                    var newCorrections = await storedCorrections
                                        .readCorrections();
                                    //print('is this correct? $day');
                                    Timings instance = Timings(
                                        lat: latitude,
                                        long: longitude,
                                        day: day,
                                        month: month,
                                        year: year,
                                        corrections: newCorrections);
                                    await instance.getTimings();
                                    prayers = instance.prayers;
                                    CreateSchedule getSchedule = CreateSchedule(
                                        prayers: prayers,
                                        prewait: currentValueStartMap,
                                        wait: currentValueEndMap);
                                    await getSchedule.createSchedule();
                                    scheduleStart = getSchedule.scheduleStart;
                                    scheduleEnd = getSchedule.scheduleEnd;

                                    setState(() {
                                      for (String key in oldPrayers.keys) {
                                        oldPrayers[key] = DateFormat.Hm()
                                            .format(prayers[key]!);
                                        gpsvisible = false;
                                        timingsvisible2 = false;
                                        confirmvisible = false;
                                        timingsvisible = true;
                                        schedulevisible = true;
                                      }
                                    });
                                  } catch (e) {
                                    //print(e);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                AppLocalizations.of(context)!
                                                    .failedMessage)));
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.grey[900],
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  void scheduleSilence() async {
    try {
      for (int i = 0; i < 5; i++) {
        if (DateTime.parse(scheduleStart.values.toList()[i])
            .isAfter(DateTime.now())) {
          await AndroidAlarmManager.cancel(100 - i);

          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleStart.values.toList()[i]),
              100 - i,
              rescheduleOnReboot: true,
              exact: true,
              createSilence);

          await AndroidAlarmManager.cancel(1000 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleEnd.values.toList()[i]),
              1000 - i,
              rescheduleOnReboot: true,
              exact: true,
              disableSilence);

          //print('is this working?${scheduleStart.values.toList()[i]}');
        }
        if (DateTime.parse(scheduleStart.values.toList()[i])
            .isBefore(DateTime.now())) {
          await AndroidAlarmManager.cancel(100 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleStart.values.toList()[i])
                  .add(const Duration(days: 1)),
              100 - i,
              rescheduleOnReboot: true,
              exact: true,
              createSilence);
          await AndroidAlarmManager.cancel(1000 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleEnd.values.toList()[i])
                  .add(const Duration(days: 1)),
              1000 - i,
              rescheduleOnReboot: true,
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
          await AndroidAlarmManager.cancel(100 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleStart.values.toList()[i]),
              100 - i,
              rescheduleOnReboot: true,
              exact: true,
              createSilence);
          await AndroidAlarmManager.cancel(1000 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleEnd.values.toList()[i]),
              1000 - i,
              rescheduleOnReboot: true,
              exact: true,
              disableSilence);

          //print('is this working?${scheduleStart.values.toList()[i]}');
        }
        if (DateTime.parse(scheduleStart.values.toList()[i])
            .isBefore(DateTime.now())) {
          await AndroidAlarmManager.cancel(100 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleStart.values.toList()[i])
                  .add(const Duration(days: 1)),
              100 - i,
              rescheduleOnReboot: true,
              exact: true,
              createSilence);
          await AndroidAlarmManager.cancel(1000 - i);
          await AndroidAlarmManager.oneShotAt(
              DateTime.parse(scheduleEnd.values.toList()[i])
                  .add(const Duration(days: 1)),
              1000 - i,
              rescheduleOnReboot: true,
              exact: true,
              disableSilence);
        }
      }

      //print(e);
    }
  }
}
