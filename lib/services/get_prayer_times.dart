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
      print(' is this from here perhapse ?? $e');
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
  final TimingsStorage timingsstorage = TimingsStorage();

  Timings(
      {required this.lat,
      required this.long,
      required this.day,
      required this.month,
      required this.year});

  Future<void> getTimings() async {
    try {
      final file = await timingsstorage._localFile;
      final contents = await file.readAsString();
      data = jsonDecode(contents);

      if (lat == data[0]['meta']['latitude'] &&
          long == data[0]['meta']['longitude']) {
        data = data;
      } else {
        try {
          Response response = await get(Uri.parse(
              'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&month=$month&year=$year'));
          data = jsonDecode(response.body)["data"];
          print('accessed api');
          // print(data);
          TimingsStorage().writeTimings(data);
        } catch (e) {
          print(' this is from here $e');
        }
      }
    } catch (e) {
      print('this is from over head wow $e');
      Response response = await get(Uri.parse(
          'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&month=$month&year=$year'));
      data = jsonDecode(response.body)["data"];
      print('accessed api');
      // print(data);
      TimingsStorage().writeTimings(data);
    }
  }
}
