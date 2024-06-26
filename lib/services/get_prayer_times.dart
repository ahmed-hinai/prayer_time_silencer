import 'package:http/http.dart';
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

  Future<dynamic> readTimings() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      //print(' is this from here perhapse ?? $e');
      return '';
    }
  }

  Future<File> writeTimings(response) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString(json.encode(response));
  }
}

class Timings {
  late double lat;
  late double long;
  late int day;
  late int month;
  late int year;
  late var data;
  late Map corrections;
  late Map oldCorrections;
  Map<String, DateTime> prayers = {};
  final TimingsStorage timingsstorage = TimingsStorage();

  Timings(
      {required this.lat,
      required this.long,
      required this.day,
      required this.month,
      required this.year,
      required this.corrections});

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

      if (lat == data[0]['meta']['latitude'] &&
          long == data[0]['meta']['longitude']) {
        data = data;
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
      } else {
        try {
          int fajr = int.parse(corrections.values.toList()[0]);
          //print(fajr);
          int dhuhr = int.parse(corrections.values.toList()[1]);
          int asr = int.parse(corrections.values.toList()[2]);
          int maghrib = int.parse(corrections.values.toList()[3]);
          int isha = int.parse(corrections.values.toList()[4]);
          //print('hmmmm? $fajr $dhuhr $asr $maghrib $isha');

          Response response = await get(Uri.parse(
              'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&year=$year&tune=0,$fajr,0,$dhuhr,$asr,$maghrib,0,$isha,0'));
          data = jsonDecode(response.body)["data"];
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
          //print('accessed api');
          // //print(data);
          TimingsStorage().writeTimings(data);
        } catch (e) {
          //print(corrections.values.toList()[0]);
          //print(' this is from here $e');

          int fajr = 0;
          int dhuhr = 0;
          int asr = 0;
          int maghrib = 0;
          int isha = 0;
          Response response = await get(Uri.parse(
              'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&year=$year&tune=0,$fajr,0,$dhuhr,$asr,$maghrib,0,$isha,0'));
          data = jsonDecode(response.body)["data"];
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
          //print('accessed api');
          TimingsStorage().writeTimings(data);
        }
      }
    } catch (e) {
      try {
        int fajr = corrections.values.toList()[0];
        int dhuhr = corrections.values.toList()[1];
        int asr = corrections.values.toList()[2];
        int maghrib = corrections.values.toList()[3];
        int isha = corrections.values.toList()[4];
        //print('$fajr $dhuhr $asr $maghrib $isha}');
        //print('this is from over head wow 1 $e');
        Response response = await get(Uri.parse(
            'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&year=$year&tune=0,$fajr,0,$dhuhr,$asr,$maghrib,0,$isha,0'));
        data = jsonDecode(response.body)["data"];
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
        //print('accessed api');
        // //print(data);
        TimingsStorage().writeTimings(data);
      } catch (e) {
        //print(corrections);
        int fajr = 0;
        int dhuhr = 0;
        int asr = 0;
        int maghrib = 0;
        int isha = 0;
        //print('this is from over head wow  2$e');
        Response response = await get(Uri.parse(
            'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&year=$year&tune=0,$fajr,0,$dhuhr,$asr,$maghrib,0,$isha,0'));
        data = jsonDecode(response.body)["data"];
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
        //print('accessed api');
        // //print(data);
        TimingsStorage().writeTimings(data);
      }
    }
  }
}

class RebuildTimings {
  late double lat;
  late double long;
  late int day;
  late int month;
  late int year;
  late var data;
  late Map corrections;
  late Map oldCorrections;
  Map<String, DateTime> prayers = {};
  final TimingsStorage timingsstorage = TimingsStorage();

  RebuildTimings(
      {required this.lat,
      required this.long,
      required this.day,
      required this.month,
      required this.year,
      required this.corrections});

  Future<void> getTimings() async {
    try {
      int fajr = int.parse(corrections.values.toList()[0]);
      int dhuhr = int.parse(corrections.values.toList()[1]);
      int asr = int.parse(corrections.values.toList()[2]);
      int maghrib = int.parse(corrections.values.toList()[3]);
      int isha = int.parse(corrections.values.toList()[4]);
      Response response = await get(Uri.parse(
          'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&year=$year&tune=0,$fajr,0,$dhuhr,$asr,$maghrib,0,$isha,0'));
      data = jsonDecode(response.body)["data"];
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
      //print('accessed api');
      // //print(data);
      TimingsStorage().writeTimings(data);
    } catch (e) {
      //print(e);
    }
  }
}
