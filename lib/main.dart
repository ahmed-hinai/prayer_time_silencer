import 'package:flutter/material.dart';
import 'package:prayer_time_silencer/pages/home.dart';
import 'package:prayer_time_silencer/pages/loading.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => Loading(),
      '/home': (context) => Home(),
    },
  ));
}
