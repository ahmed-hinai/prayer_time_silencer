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
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: TextField(
              onSubmitted: ((text) async {
                GetLocation newLocation = GetLocation(location: text);
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
                                  borderRadius: BorderRadius.circular(20.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    '${prayers.keys.toList()[index]}',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 26.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    '${prayers.values.toList()[index]}',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 26.0),
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
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          MuteSystemSounds().muteSystemSounds();
        },
      ),
    );
  }
}
