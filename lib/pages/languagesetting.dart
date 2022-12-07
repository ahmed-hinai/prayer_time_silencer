import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:prayer_time_silencer/main.dart';

class LanguageSetting extends StatefulWidget {
  const LanguageSetting({super.key});

  @override
  State<LanguageSetting> createState() => _LanguageSettingState();
}

class _LanguageSettingState extends State<LanguageSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.language),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            onTap: () async {
              MyAppState().setLocalePref('en');
              setState(() {
                MyApp.of(context)
                    ?.setLocale(const Locale.fromSubtags(languageCode: 'en'));
              });
            },
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black, width: .2),
              borderRadius: BorderRadius.circular(0),
            ),
            tileColor: Colors.grey[800],
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!.english,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
          ListTile(
            onTap: () async {
              MyAppState().setLocalePref('ar');
              setState(() {
                MyApp.of(context)
                    ?.setLocale(const Locale.fromSubtags(languageCode: 'ar'));
              });
            },
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black, width: .2),
              borderRadius: BorderRadius.circular(0),
            ),
            tileColor: Colors.grey[800],
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!.arabic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
          ListTile(
            onTap: () async {
              MyAppState().setLocalePref('ur');
              setState(() {
                MyApp.of(context)
                    ?.setLocale(const Locale.fromSubtags(languageCode: 'ur'));
              });
            },
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black, width: .2),
              borderRadius: BorderRadius.circular(0),
            ),
            tileColor: Colors.grey[800],
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!.urdu,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
