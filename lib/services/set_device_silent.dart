import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();
// flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//     AndroidFlutterLocalNotificationsPlugin>().requestPermission();

class MuteSystemSounds {
  late var status;
  late bool isGranted;

  void muteSystemSounds() async {
    isGranted = (await PermissionHandler.permissionsGranted)!;
    if (!isGranted) {
      // Opens the Do Not Disturb Access settings to grant the access
      await PermissionHandler.openDoNotDisturbSetting();
    }
    if (isGranted) {
      try {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
      } catch (e) {
        print('Please enable permissions required');
        print(e);
      }
    }
  }
}
