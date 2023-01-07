import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

final service = FlutterBackgroundService();

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  void setupHome() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    PermissionStatus ignorebatteryOpGranted =
        await Permission.ignoreBatteryOptimizations.status;
    if (ignorebatteryOpGranted.isGranted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(
          barrierColor: Color.fromARGB(212, 4, 42, 74),
          context: context,
          builder: (BuildContext Dialogcontext) => AlertDialog(
                backgroundColor: Color.fromARGB(255, 7, 64, 111),
                actions: [
                  TextButton(
                      onPressed: () async {
                        Navigator.of(Dialogcontext).pop();
                        await Future.delayed(Duration(milliseconds: 100));
                        await Permission.ignoreBatteryOptimizations
                            .request()
                            .then((value) async {
                          if (value.isDenied) {
                            service.invoke("stopService");
                            await SystemChannels.platform
                                .invokeMethod<void>('SystemNavigator.pop');
                          } else {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.ok))
                ],
                title: Text(
                  AppLocalizations.of(context)!.batteryOPRequestTitle,
                  style: const TextStyle(color: Colors.white),
                ),
                content: Text(
                    AppLocalizations.of(context)!.batteryOPRequestBody,
                    style: const TextStyle(color: Colors.white)),
              ));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupHome();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Color.fromARGB(255, 248, 246, 246),
        body: Center(
            child: SpinKitChasingDots(
          color: Color.fromARGB(255, 7, 64, 111),
          size: 70.0,
        )));
  }
}
