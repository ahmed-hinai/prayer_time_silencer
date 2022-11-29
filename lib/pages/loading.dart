import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  void setupTimings() async {
    Timings instance =
        Timings(lat: 25.1, long: 58.1, day: 5, month: 3, year: 2021);
    await instance.getTimings();
    Navigator.pushReplacementNamed(context, '/home',
        arguments: {'data': instance.data});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupTimings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Center(
            child: SpinKitCubeGrid(
          color: Colors.white,
          size: 70.0,
        )));
  }
}
