import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/silence_scheduler.dart';
import 'package:prayer_time_silencer/services/wait_and_prewait_store.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  void setupHome() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    Navigator.pushReplacementNamed(context, '/home');
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
