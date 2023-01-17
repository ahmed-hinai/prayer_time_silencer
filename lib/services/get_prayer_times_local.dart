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

class TimingsLocal {
  late int day;
  late int month;
  late int year;
  late var data;
  Map<String, DateTime> prayers = {};
  TimingsStorage timingsstorage = TimingsStorage();

  TimingsLocal({required this.day, required this.month, required this.year});

  Future<void> getTimings() async {
    try {
      final file = await timingsstorage._localFile;
      final contents = await file.readAsString();
      data = jsonDecode(contents);
      prayers['Fajr'] = DateTime.parse(
          '$year-${month.toString().length < 2 ? month.toString().padLeft(2, '0'.replaceAll('"', '')) : month}-${day.toString().length < 2 ? day.toString().padLeft(2, '0'.replaceAll('"', '')) : day} ${data[day - 1]['timings']['Fajr'].substring(0, 5)}');
      prayers['Dhuhr'] = DateTime.parse(
          '$year-${month.toString().length < 2 ? month.toString().padLeft(2, '0'.replaceAll('"', '')) : month}-${day.toString().length < 2 ? day.toString().padLeft(2, '0'.replaceAll('"', '')) : day} ${data[day - 1]['timings']['Dhuhr'].substring(0, 5)}');
      prayers['Asr'] = DateTime.parse(
          '$year-${month.toString().length < 2 ? month.toString().padLeft(2, '0'.replaceAll('"', '')) : month}-${day.toString().length < 2 ? day.toString().padLeft(2, '0'.replaceAll('"', '')) : day} ${data[day - 1]['timings']['Asr'].substring(0, 5)}');
      prayers['Maghrib'] = DateTime.parse(
          '$year-${month.toString().length < 2 ? month.toString().padLeft(2, '0'.replaceAll('"', '')) : month}-${day.toString().length < 2 ? day.toString().padLeft(2, '0'.replaceAll('"', '')) : day} ${data[day - 1]['timings']['Maghrib'].substring(0, 5)}');
      prayers['Isha'] = DateTime.parse(
          '$year-${month.toString().length < 2 ? month.toString().padLeft(2, '0'.replaceAll('"', '')) : month}-${day.toString().length < 2 ? day.toString().padLeft(2, '0'.replaceAll('"', '')) : day} ${data[day - 1]['timings']['Isha'].substring(0, 5)}');
    } catch (e) {
      print('the error is here why????');
      print(e);
    }
  }
}
