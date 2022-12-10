import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:prayer_time_silencer/main.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settings),
            centerTitle: true,
            backgroundColor: Color.fromARGB(255, 7, 64, 111)),
        body: ListView(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: .2),
                  borderRadius: BorderRadius.circular(0)),
              tileColor: Colors.grey[800],
              onTap: () {
                Navigator.pushNamed(context, '/languagesetting');
              },
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.language,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              value: MyAppState.isSchedulingON!,
              onChanged: (value) async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isRunning();

                setState(() {
                  MyAppState.isSchedulingON = !MyAppState.isSchedulingON!;
                  MyAppState().setSchedulingPref(value);
                  try {
                    if (MyAppState.isSchedulingON!) {
                      service.startService();
                    } else {
                      service.invoke("stopService");
                    }
                  } catch (e) {}
                });
              },
              shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: .2),
                  borderRadius: BorderRadius.circular(0)),
              tileColor: Colors.grey[800],
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.schedulingSetting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.schedulingSettingSubtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
