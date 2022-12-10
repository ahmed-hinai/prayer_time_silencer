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
        backgroundColor: Colors.grey[800],
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.aboutUs),
            centerTitle: true,
            backgroundColor: Color.fromARGB(255, 7, 64, 111)),
        body: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                height: 280,
                child: Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.aboutUsHello1,
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 16.0),
                        ),
                        SizedBox(
                          height: 45,
                          width: 420,
                          child: Card(
                              color: Colors.grey[700],
                              shadowColor: Colors.black,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SelectableText(
                                    'ahmedhinaibuilds@gmail.com',
                                    style: TextStyle(
                                        color: Colors.grey[100], fontSize: 16),
                                  ),
                                ),
                              )),
                        ),
                        Text(
                          AppLocalizations.of(context)!.aboutUsHello2,
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                height: 280,
                child: Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image(
                            image: const AssetImage('assets/aladhanapi.png'),
                            width: MediaQuery.of(context).size.width / 3,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.aboutUsApiTalk,
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                height: 280,
                child: Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image(
                            image: const AssetImage('assets/flutter_icon.png'),
                            width: MediaQuery.of(context).size.width / 6.5,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.aboutUsFlutterTalk,
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ]));
  }
}
