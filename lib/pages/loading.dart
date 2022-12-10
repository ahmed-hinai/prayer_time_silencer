import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:prayer_time_silencer/services/get_prayer_times_local.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  Map lastKnownStartSchedule = {};
  Map lastKnownEndSchedule = {};
  void setupHome() async {
    try {
      var start = await ScheduleStorageStart().readSchedule();
      var end = await ScheduleStorageEnd().readSchedule();

      for (var key in start.keys) {
        lastKnownStartSchedule[key] = start[key];
        lastKnownEndSchedule[key] = end[key];
      }

      TimingsLocal localinstance = TimingsLocal(
          day: DateTime.now().day,
          month: DateTime.now().month,
          year: DateTime.now().year);
      await localinstance.getTimings();
      var lastKnownPrayers = localinstance.prayers;
      // //print(lastKnownPrayers);

      await Future.delayed(Duration(milliseconds: 2000));
      Navigator.pushReplacementNamed(context, '/home', arguments: {
        'lastKnownPrayers': lastKnownPrayers,
        'lastKnownStartSchedule': lastKnownStartSchedule,
        'lastKnownEndSchedule': lastKnownEndSchedule,
      });
    } catch (e) {
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupHome();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Color.fromARGB(255, 33, 33, 33),
        body: Center(
            child: SpinKitChasingDots(
          color: Color.fromARGB(255, 7, 64, 111),
          size: 70.0,
        )));
  }
}
