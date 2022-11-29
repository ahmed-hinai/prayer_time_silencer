import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_silencer/services/get_device_location.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late double latitude;
  late double longitude;
  final int day = DateTime.now().day - 1;
  final int month = DateTime.now().month;
  final int year = DateTime.now().year;
  var icon = Icon(Icons.notifications);

  Map<String, String> prayers = {
    'Fajr': '00:00',
    'Dhuhr': '00:00',
    'Asr': '00:00',
    'Maghrib': '00:00',
    'Isha': '00:00'
  };

  late var data;
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
              return {'Logout', 'Settings'}.map((String choice) {
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
                  Timings instance = Timings(
                      lat: latitude,
                      long: longitude,
                      day: day,
                      month: month,
                      year: year);
                  await instance.getTimings();
                  data = instance.data;
                  setState(() {
                    for (String key in prayers.keys) {
                      prayers[key] = data[day]['timings'][key].substring(0, 5);
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
                data = instance.data;
                setState(() {
                  for (String key in prayers.keys) {
                    prayers[key] = data[day]['timings'][key].substring(0, 5);
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
          ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: prayers.length,
              itemBuilder: ((context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(38.0, 0.0, 38.0, 0.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(70.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    '${prayers.keys.toList()[index]}',
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
                                  borderRadius: BorderRadius.circular(70.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    '${prayers.values.toList()[index]}',
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
                  ),
                );
              })),
          SizedBox(
            height: 40.0,
          ),
        ]),
      ),
    );
  }
}
