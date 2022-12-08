import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:prayer_time_silencer/main.dart';

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
            backgroundColor: Colors.blue[900]),
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
              onChanged: (value) {
                setState(() {
                  MyAppState.isSchedulingON = !MyAppState.isSchedulingON!;
                  MyAppState().setSchedulingPref(value);
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
