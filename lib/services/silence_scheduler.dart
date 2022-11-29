import 'package:workmanager/workmanager.dart';
import 'package:prayer_time_silencer/services/set_device_silent.dart';

class CreateSchedule {
  late var data;
  final int day = DateTime.now().day - 1;
  late Map<String, String> silenceScheduel;

  CreateSchedule({this.data});

  void createSchedule() {
    data[day]['timings']['Fajr'].substring(0, 5);
    data[day]['timings']['Dhuhr'].substring(0, 5);
    data[day]['timings']['Asr'].substring(0, 5);
    data[day]['timings']['Maghrib'].substring(0, 5);
    data[day]['timings']['Isha'].substring(0, 5);
  }
}
