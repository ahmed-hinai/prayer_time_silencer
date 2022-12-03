import 'package:flutter/material.dart';

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
            title: Text('Settings'),
            centerTitle: true,
            backgroundColor: Colors.blue[900]),
        body: Column(
          children: [
            Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Corrections',
                    style: TextStyle(
                      color: Colors.grey[200],
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
              shadowColor: Colors.blue[800],
              color: Colors.blue[900],
            )
          ],
        ));
  }
}
