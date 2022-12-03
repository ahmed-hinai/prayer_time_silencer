import 'package:prayer_time_silencer/services/set_device_silent.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScheduleStorageStart {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/scheduleStart.json');
  }

  Future<dynamic> readSchedule() async {
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

  Future<File> writeSchedule(response) async {
    final file = await _localFile;

    // Write the file

    return file.writeAsString(json.encode(response));
  }
}

class ScheduleStorageEnd {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/scheduleEnd.json');
  }

  Future<dynamic> readSchedule() async {
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

  Future<File> writeSchedule(response) async {
    final file = await _localFile;

    // Write the file

    return file.writeAsString(json.encode(response));
  }
}

class CreateSchedule {
  late var prayers;
  late int prewait;
  late int wait;
  late Map<String, String> scheduleStart = {};
  late Map<String, String> scheduleEnd = {};
  ScheduleStorageStart scheduleStorageStart = ScheduleStorageStart();
  ScheduleStorageEnd scheduleStorageEnd = ScheduleStorageEnd();

  CreateSchedule(
      {required this.prayers, required this.prewait, required this.wait});

  Future<void> createSchedule() async {
    for (String key in prayers.keys) {
      scheduleStart[key] = '${prayers[key].add(Duration(minutes: prewait))}';

      scheduleEnd[key] = '${prayers[key].add(const Duration(minutes: 40))}';
      scheduleStorageStart.writeSchedule(scheduleStart);
      scheduleStorageEnd.writeSchedule(scheduleEnd);
    }
  }
}
