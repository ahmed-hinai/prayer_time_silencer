//'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&month=$month&year=$year'
import 'package:http/http.dart';
import 'package:intl/intl.dart';
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

  Future<String> readTimings() async {
    try {
      final file = await _localFile;
      if (file.existsSync()) {
        // Read the file
        final contents = await file.readAsString();
        return jsonDecode(contents);
      } else {
        final path = await _localPath;
        File('$path/timings.json').create(recursive: true);
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      // If encountering an error, return 0
      print(e);
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
  final TimingsStorage storage = TimingsStorage();

  Timings(
      {required this.lat,
      required this.long,
      required this.day,
      required this.month,
      required this.year});

  Future<void> getTimings() async {
    try {
      Response response = await get(Uri.parse(
          'http://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$long&month=$month&year=$year'));
      data = jsonDecode(response.body)["data"];
      print('accessed api');
      // print(data);
      TimingsStorage().writeTimings(data);
    } catch (e) {
      print(e);
    }
  }
}
