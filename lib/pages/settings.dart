import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue[900],
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settings),
            centerTitle: true,
            backgroundColor: Colors.blue[900]),
        body: ListView());
  }
}
