class TimeObject {
  late String time;
  late int hour;
  late int minute;
  late int timeInMinutes;
  TimeObject({required this.time});

  int setTime() {
    hour = int.parse(time.substring(0, 2));
    minute = int.parse(time.substring(3, 5));
    timeInMinutes = (hour * 60) + minute;

    return timeInMinutes;
  }
}
