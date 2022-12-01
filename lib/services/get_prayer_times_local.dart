import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TimingsStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/timings.json');
  }
}

class Timings {
  late int day;
  late int month;
  late int year;
  late var data;
  Map<String, DateTime> prayers = {};
  final TimingsStorage timingsstorage = TimingsStorage();

  Timings({required this.day, required this.month, required this.year});

  Future<void> getTimings() async {
    try {
      final file = await timingsstorage._localFile;
      final contents = await file.readAsString();
      data = jsonDecode(contents);
      prayers['Fajr'] = DateTime.parse(
          '$year-$month-$day ${data[day]['timings']['Fajr'].substring(0, 5)}');
      prayers['Dhuhr'] = DateTime.parse(
          '$year-$month-$day ${data[day]['timings']['Dhuhr'].substring(0, 5)}');
      prayers['Asr'] = DateTime.parse(
          '$year-$month-$day ${data[day]['timings']['Asr'].substring(0, 5)}');
      prayers['Maghrib'] = DateTime.parse(
          '$year-$month-$day ${data[day]['timings']['Maghrib'].substring(0, 5)}');
      prayers['Isha'] = DateTime.parse(
          '$year-$month-$day ${data[day]['timings']['Isha'].substring(0, 5)}');
    } catch (e) {
      print(e);
    }
  }
}
