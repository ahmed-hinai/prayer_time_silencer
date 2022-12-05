import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_silencer/services/get_device_location.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:prayer_time_silencer/services/corrections_store.dart';
import 'package:prayer_time_silencer/services/wait_and_prewait_store.dart';
import 'package:prayer_time_silencer/services/push_local_notifications.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:prayer_time_silencer/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _enabled = true;
  int _status = 0;
  int _currentValueStart = 5;
  int _currentValueEnd = 40;
  List<DateTime> _events = [];
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
      print('is this really a new start${newStart}');
      for (String key in newStart.keys) {
        currentValueStartMap[key] = newStart[key];
      }
    } catch (e) {
      print(e);
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
      print(e);
    }
  }

  Map oldValueEndMap = {};
  void initState() {
    super.initState();
    initPlatformState();
    getLocaltimings();
    getValueStartMap();
    getValueEndMap();
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

  late var timeSelected;

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
  List<bool> selections = [true, false, false, false, false];
  Map<String, dynamic> oldPrayers = {
    'Fajr': DateFormat.Hm().format(DateTime.now()),
    'Dhuhr': DateFormat.Hm().format(DateTime.now()),
    'Asr': DateFormat.Hm().format(DateTime.now()),
    'Maghrib': DateFormat.Hm().format(DateTime.now()),
    'Isha': DateFormat.Hm().format(DateTime.now())
  };

  List localizedPrayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  late var data;
  static Map<String, DateTime> prayers = {};
  Map<String, String> scheduleStart = {};
  Map<String, String> scheduleEnd = {};

  void getLocaltimings() async {
    try {
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
    } catch (e) {
      print(e);
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
        print('back button pressed');
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
          backgroundColor: Colors.blue[900],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    AppLocalizations.of(context)!.enterToRetrievePrayerTimes,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: TextField(
                    onSubmitted: ((text) async {
                      Navigator.pop(context);
                      GetLocationFromInput newLocation =
                          GetLocationFromInput(location: text);
                      await newLocation.getLocationFromUserInput();
                      latitude = newLocation.latitude;
                      longitude = newLocation.longitude;
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
                          timingsvisible = true;
                          schedulevisible = true;
                          confirmvisible = false;
                          gpsvisible = false;
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
                      hintText: AppLocalizations.of(context)!.enterLocation,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        appBar: AppBar(
          elevation: 3.0,
          title: Text(""),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
          actions: [
            Visibility(
                visible: false,
                maintainInteractivity: false,
                child: Switch(value: _enabled, onChanged: _onClickEnable)),
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
                      await choice == AppLocalizations.of(context)!.aboutUs
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
                                        selectedBorderColor: Colors.blue[600],
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
                                                  color: Colors.blue[900],
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
                                                        style: TextStyle(
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
                                                                    .all(8.0),
                                                            child: Text(
                                                              '${DateFormat.Hm().format(DateTime.parse(scheduleStart.values.toList()[index]))}',
                                                              style: TextStyle(
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
                                                                    .all(8.0),
                                                            child: Text(
                                                                '${DateFormat.Hm().format(DateTime.parse(scheduleEnd.values.toList()[index]))}',
                                                                style: TextStyle(
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
                                                  color: Colors.blue[900],
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
                                                        style: TextStyle(
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
                        Text(
                          'Begin here',
                          style: TextStyle(color: Colors.white, fontSize: 18.0),
                        ),
                        Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                          size: 30.0,
                        ),
                        IconButton(
                          color: Colors.blue[900],
                          onPressed: () async {
                            GetLocationFromGPS newLocation =
                                GetLocationFromGPS();
                            await newLocation.getLocationFromGPS();
                            latitude = newLocation.latitude;
                            longitude = newLocation.longitude;
                            CorrectionsStorage storedCorrections =
                                CorrectionsStorage();
                            var newCorrections =
                                await storedCorrections.readCorrections();
                            print('is this correct? $day');
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
                                schedulevisible = true;
                              }
                            });
                            ;
                          },
                          icon: Icon(Icons.location_on),
                          iconSize: 180,
                          tooltip: 'gets device location',
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
                                    textStyle: TextStyle(
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
                                  textStyle: TextStyle(
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
                      padding: const EdgeInsets.fromLTRB(28.0, 0.0, 28.0, 0.0),
                      child: Row(children: [
                        Expanded(
                          child: Card(
                              color: Colors.grey[600],
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    18.0, 8.0, 18.0, 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.startSchedule,
                                  style: TextStyle(
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
                                style: TextStyle(
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
                      padding: const EdgeInsets.fromLTRB(30.0, 8.0, 30.0, 8.0),
                      child: Card(
                        color: Colors.grey[800],
                        child: Row(
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    18.0, 8.0, 18.0, 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!.confirmSchedule,
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      0.0, 48.0, 0.0, 48.0),
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 30.0),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  elevation: 20.0,
                                ),
                                onPressed: () async {
                                  bool isGranted = (await PermissionHandler
                                      .permissionsGranted)!;
                                  scheduleSilence();
                                  if (!isGranted) {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            AlertDialog(
                                              actions: [
                                                TextButton(
                                                    onPressed: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                      await PermissionHandler
                                                              .openDoNotDisturbSetting()
                                                          .then((value) =>
                                                              scheduleSilence());
                                                    },
                                                    child: const Text('Ok'))
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
                ),
                SafeArea(
                  child: Visibility(
                      visible: schedulevisible,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700]),
                        child: Text(AppLocalizations.of(context)!.corrections),
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
                          print((result['prayers']));

                          Map correctedPrayers = {};
                          correctedPrayers['Fajr'] = result['prayers']['Fajr'];
                          correctedPrayers['Dhuhr'] =
                              result['prayers']['Dhuhr'];
                          correctedPrayers['Asr'] = result['prayers']['Asr'];
                          correctedPrayers['Maghrib'] =
                              result['prayers']['Maghrib'];
                          correctedPrayers['Isha'] = result['prayers']['Isha'];
                          CreateSchedule getNewSchedule = CreateSchedule(
                              prayers: correctedPrayers,
                              prewait: currentValueStartMap,
                              wait: currentValueEndMap);
                          await getNewSchedule.createSchedule();
                          print(
                              'was is das ${getNewSchedule.scheduleStart['Fajr']}');
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
                      )),
                ),
                Visibility(
                    visible: confirmvisible,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(28.0, 0.0, 28.0, 250.0),
                      child: Column(
                        children: [
                          Card(
                            color: Colors.blue[900],
                            child: Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .confirmationMessage,
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Visibility(
                      visible: confirmvisible,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: IconButton(
                          color: Colors.blue[900],
                          onPressed: () async {
                            setState(() {
                              gpsvisible = false;
                              schedulevisible = true;
                              confirmvisible = false;
                              timingsvisible = true;
                            });
                          },
                          icon: Icon(Icons.edit),
                          iconSize: 40,
                          tooltip: 'Edit current scheduling',
                        ),
                      ),
                    ),
                    Visibility(
                      visible: confirmvisible,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            IconButton(
                              color: Colors.blue[900],
                              onPressed: () async {
                                GetLocationFromGPS newLocation =
                                    GetLocationFromGPS();
                                await newLocation.getLocationFromGPS();
                                latitude = newLocation.latitude;
                                longitude = newLocation.longitude;
                                var newCorrections = await CorrectionsStorage()
                                    .readCorrections();
                                print('is this correct? $day');
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
                                    schedulevisible = true;
                                    confirmvisible = false;
                                    timingsvisible = true;
                                  }
                                });
                                ;
                              },
                              icon: Icon(Icons.location_on),
                              iconSize: 40,
                              tooltip: 'gets device location',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
      if (DateTime.parse(scheduleStart.values.toList()[0])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 9,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[0]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[0]),
            99,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[0]),
            999,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence1);

        print('is this working?${scheduleStart.values.toList()[0]}');
      }

      if (DateTime.parse(scheduleStart.values.toList()[1])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 1,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[1]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[1]),
            11,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);
        print('is this working?${scheduleStart.values.toList()[1]}');

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[1]),
            111,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence2);
      }

      if (DateTime.parse(scheduleStart.values.toList()[2])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 2,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[2]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[2]),
            22,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[2]),
            222,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence3);
        print('is this working?${scheduleStart.values.toList()[2]}');
      }

      if (DateTime.parse(scheduleStart.values.toList()[3])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 3,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[3]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[3]),
            33,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[3]),
            333,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence4);
        print('is this working?${scheduleStart.values.toList()[3]}');
      }

      if (DateTime.parse(scheduleStart.values.toList()[4])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 4,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[4]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[4]),
            44,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[4]),
            444,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence5);
        print('is this working?${scheduleStart.values.toList()[4]}');
      } else {}
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
      if (DateTime.parse(scheduleStart.values.toList()[0])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 9,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[0]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[0]),
            99,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[0]),
            999,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence1);

        print('is this working?${scheduleStart.values.toList()[0]}');
      }

      if (DateTime.parse(scheduleStart.values.toList()[1])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 1,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[1]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[1]),
            11,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);
        print('is this working?${scheduleStart.values.toList()[1]}');

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[1]),
            111,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence2);
      }

      if (DateTime.parse(scheduleStart.values.toList()[2])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 2,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[2]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[2]),
            22,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[2]),
            222,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence3);
        print('is this working?${scheduleStart.values.toList()[2]}');
      }

      if (DateTime.parse(scheduleStart.values.toList()[3])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 3,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[3]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[3]),
            33,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[3]),
            333,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence4);
        print('is this working?${scheduleStart.values.toList()[3]}');
      }

      if (DateTime.parse(scheduleStart.values.toList()[4])
          .isAfter(DateTime.now())) {
        LocalNotifications notifySilence = LocalNotifications();

        await notifySilence.showNotification(
            id: 4,
            title: 'Prayer Time Silencer',
            body: 'Your Phone is being silenced',
            schedule: DateTime.parse(scheduleStart.values.toList()[4]));

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleStart.values.toList()[4]),
            44,
            rescheduleOnReboot: true,
            exact: true,
            createSilence);

        await AndroidAlarmManager.oneShotAt(
            DateTime.parse(scheduleEnd.values.toList()[4]),
            444,
            rescheduleOnReboot: true,
            exact: true,
            disableSilence5);
        print('is this working?${scheduleStart.values.toList()[4]}');
      } else {}

      print(e);
    }
  }
}
