import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_silencer/services/get_device_location.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
}
