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
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.aboutUs),
            centerTitle: true,
            backgroundColor: Colors.blue[900]),
        body: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                height: 280,
                child: Card(
                  color: Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "Hello! thank you for using my app. If you have any queries please feel free to contact me here:",
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 18.0),
                        ),
                        SizedBox(
                          height: 50,
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
                                        color: Colors.grey[100], fontSize: 18),
                                  ),
                                ),
                              )),
                        ),
                        Text(
                          "You can also leave a review on the Google Play store citing any issues you may have or features you would like implimented.",
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 18.0),
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
                  color: Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Image(
                          image: AssetImage('assets/aladhanapi.png'),
                          width: MediaQuery.of(context).size.width / 2.3,
                        ),
                        Text(
                          "This application uses the open source API provided by the good people at aladhan.com. The API serves as a main part of the functionality of this app.",
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 18.0),
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
                  color: Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "",
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 18.0),
                        ),
                        Text(
                          "",
                          style: TextStyle(
                              color: Colors.grey[100], fontSize: 18.0),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ]));
  }
}
