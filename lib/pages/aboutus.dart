import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Aboutus extends StatefulWidget {
  const Aboutus({super.key});

  @override
  State<Aboutus> createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blue[900],
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.aboutUs),
            centerTitle: true,
            backgroundColor: Colors.blue[900]),
        body: Column());
  }
}
