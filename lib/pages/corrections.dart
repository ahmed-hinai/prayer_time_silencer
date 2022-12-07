import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_silencer/services/get_prayer_times.dart';
import 'package:prayer_time_silencer/services/corrections_store.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Corrections extends StatefulWidget {
  const Corrections({super.key});
  @override
  State<Corrections> createState() => _SettingsState();
}

class _SettingsState extends State<Corrections> {
  CorrectionsStorage correctionsStorage = CorrectionsStorage();
  Map currentValue = {
    'Fajr': '0',
    'Dhuhr': '0',
    'Asr': '0',
    'Maghrib': '0',
    'Isha': '0'
  };
  Map oldCurrentValue = {};
  Future<void> defineValues() async {
    try {
      print('???${await correctionsStorage.readCorrections()}');
      Map currentValueStored = await correctionsStorage.readCorrections();
      setState(() {
        for (var key in currentValueStored.keys) {
          currentValue['$key'] = currentValueStored[key];
        }
      });
    } catch (e) {
      print('is this from here $e');
    }
  }

  @override
  void initState() {
    super.initState();
    defineValues();
  }

  late var prayers;
  late var importedPrayers = ModalRoute.of(context)?.settings.arguments as Map;

  @override
  Widget build(BuildContext context) {
    prayers = importedPrayers.values.toList()[0];
    late double latitude = importedPrayers.values.toList()[1];
    late double longitude = importedPrayers.values.toList()[2];
    late int day = importedPrayers.values.toList()[3];
    late int month = importedPrayers.values.toList()[4];
    late int year = importedPrayers.values.toList()[5];
    return WillPopScope(
      onWillPop: (() async {
        CreateCorrections createCorrections =
            CreateCorrections(importedCorrections: currentValue);
        RebuildTimings timings = RebuildTimings(
            lat: latitude,
            long: longitude,
            day: day,
            month: month,
            year: year,
            corrections: currentValue);
        Navigator.pop(context, {'prayers': prayers});
        await timings.getTimings();
        await createCorrections.createCorrections();

        return false;
      }),
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.corrections),
            centerTitle: true,
            backgroundColor: Colors.blue[900]),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Card(
              shadowColor: Colors.blue[800],
              color: Colors.blue[900],
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.correctionsMessage,
                          style: TextStyle(
                            color: Colors.grey[200],
                            fontSize: 17.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              child: ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Card(
                    shadowColor: Colors.blue[800],
                    color: Colors.blue[900],
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(28.0, 8.0, 28.0, 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.fajr,
                        style: TextStyle(
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 2.0,
                            )
                          ],
                          color: Colors.grey[200],
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    // ignore: sort_child_properties_last
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(70.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      DateFormat.Hm().format(prayers['Fajr']),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              child: NumberPicker(
                                  itemHeight: 38.0,
                                  selectedTextStyle: const TextStyle(
                                      fontSize: 18.0, color: Colors.blueAccent),
                                  textStyle: TextStyle(
                                      fontSize: 12.0, color: Colors.grey[800]),
                                  minValue: -60,
                                  maxValue: 60,
                                  value: int.parse(currentValue['Fajr']),
                                  onChanged: (value) => setState(() {
                                        oldCurrentValue['Fajr'] =
                                            currentValue['Fajr'];
                                        currentValue['Fajr'] = value.toString();
                                        prayers['Fajr'] = DateTime.parse(
                                                prayers['Fajr'].toString())
                                            .add(Duration(
                                                minutes: int.parse(
                                                    currentValue['Fajr'])))
                                            .subtract(Duration(
                                                minutes: int.parse(
                                                    oldCurrentValue['Fajr'])));
                                      })),
                            ),
                          ],
                        ),
                      ),
                    ),
                    shadowColor: Colors.blue[800],
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Card(
                    shadowColor: Colors.blue[800],
                    color: Colors.blue[900],
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(28.0, 8.0, 28.0, 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.dhuhr,
                        style: TextStyle(
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 2.0,
                            )
                          ],
                          color: Colors.grey[200],
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    // ignore: sort_child_properties_last
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(70.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      DateFormat.Hm().format(prayers['Dhuhr']),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              child: NumberPicker(
                                  itemHeight: 38.0,
                                  selectedTextStyle: const TextStyle(
                                      fontSize: 18.0, color: Colors.blueAccent),
                                  textStyle: TextStyle(
                                      fontSize: 12.0, color: Colors.grey[800]),
                                  minValue: -60,
                                  maxValue: 60,
                                  value: int.parse(currentValue['Dhuhr']),
                                  onChanged: (value) => setState(() {
                                        oldCurrentValue['Dhuhr'] =
                                            currentValue['Dhuhr'];
                                        currentValue['Dhuhr'] =
                                            value.toString();
                                        prayers['Dhuhr'] = DateTime.parse(
                                                prayers['Dhuhr'].toString())
                                            .add(Duration(
                                                minutes: int.parse(
                                                    currentValue['Dhuhr'])))
                                            .subtract(Duration(
                                                minutes: int.parse(
                                                    oldCurrentValue['Dhuhr'])));
                                      })),
                            ),
                          ],
                        ),
                      ),
                    ),
                    shadowColor: Colors.blue[800],
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Card(
                    shadowColor: Colors.blue[800],
                    color: Colors.blue[900],
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(28.0, 8.0, 28.0, 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.asr,
                        style: TextStyle(
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 2.0,
                            )
                          ],
                          color: Colors.grey[200],
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    // ignore: sort_child_properties_last
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(70.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      DateFormat.Hm().format(prayers['Asr']),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              child: NumberPicker(
                                  itemHeight: 38.0,
                                  selectedTextStyle: const TextStyle(
                                      fontSize: 18.0, color: Colors.blueAccent),
                                  textStyle: TextStyle(
                                      fontSize: 12.0, color: Colors.grey[800]),
                                  minValue: -60,
                                  maxValue: 60,
                                  value: int.parse(currentValue['Asr']),
                                  onChanged: (value) => setState(() {
                                        oldCurrentValue['Asr'] =
                                            currentValue['Asr'];
                                        currentValue['Asr'] = value.toString();
                                        prayers['Asr'] = DateTime.parse(
                                                prayers['Asr'].toString())
                                            .add(Duration(
                                                minutes: int.parse(
                                                    currentValue['Asr'])))
                                            .subtract(Duration(
                                                minutes: int.parse(
                                                    oldCurrentValue['Asr'])));
                                      })),
                            ),
                          ],
                        ),
                      ),
                    ),
                    shadowColor: Colors.blue[800],
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Card(
                    shadowColor: Colors.blue[800],
                    color: Colors.blue[900],
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(28.0, 8.0, 28.0, 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.maghrib,
                        style: TextStyle(
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 2.0,
                            )
                          ],
                          color: Colors.grey[200],
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    // ignore: sort_child_properties_last
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(70.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      DateFormat.Hm().format(prayers['Maghrib']),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              child: NumberPicker(
                                  itemHeight: 38.0,
                                  selectedTextStyle: const TextStyle(
                                      fontSize: 18.0, color: Colors.blueAccent),
                                  textStyle: TextStyle(
                                      fontSize: 12.0, color: Colors.grey[800]),
                                  minValue: -60,
                                  maxValue: 60,
                                  value: int.parse(currentValue['Maghrib']),
                                  onChanged: (value) => setState(() {
                                        oldCurrentValue['Maghrib'] =
                                            currentValue['Maghrib'];
                                        currentValue['Maghrib'] =
                                            value.toString();
                                        prayers['Maghrib'] = DateTime.parse(
                                                prayers['Maghrib'].toString())
                                            .add(Duration(
                                                minutes: int.parse(
                                                    currentValue['Maghrib'])))
                                            .subtract(Duration(
                                                minutes: int.parse(
                                                    oldCurrentValue[
                                                        'Maghrib'])));
                                      })),
                            ),
                          ],
                        ),
                      ),
                    ),
                    shadowColor: Colors.blue[800],
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Card(
                    shadowColor: Colors.blue[800],
                    color: Colors.blue[900],
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(28.0, 8.0, 28.0, 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.isha,
                        style: TextStyle(
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 2.0,
                            )
                          ],
                          color: Colors.grey[200],
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    // ignore: sort_child_properties_last
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.blue[900],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(70.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      DateFormat.Hm().format(prayers['Isha']),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              child: NumberPicker(
                                  itemHeight: 38.0,
                                  selectedTextStyle: const TextStyle(
                                      fontSize: 18.0, color: Colors.blueAccent),
                                  textStyle: TextStyle(
                                      fontSize: 12.0, color: Colors.grey[800]),
                                  minValue: -60,
                                  maxValue: 60,
                                  value: int.parse(currentValue['Isha']),
                                  onChanged: (value) => setState(() {
                                        oldCurrentValue['Isha'] =
                                            currentValue['Isha'];
                                        currentValue['Isha'] = value.toString();
                                        prayers['Isha'] = DateTime.parse(
                                                prayers['Isha'].toString())
                                            .add(Duration(
                                                minutes: int.parse(
                                                    currentValue['Isha'])))
                                            .subtract(Duration(
                                                minutes: int.parse(
                                                    oldCurrentValue['Isha'])));
                                      })),
                            ),
                          ],
                        ),
                      ),
                    ),
                    shadowColor: Colors.blue[800],
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ]))
        ]),
      ),
    );
  }
}
