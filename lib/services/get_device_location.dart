import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GetLocationFromInput {
  late String location;
  double longitude = 0.0;
  double latitude = 0.0;

  GetLocationFromInput({required this.location});

  Future<void> getLocationFromUserInput() async {
    try {
      List coordsWrapped = await locationFromAddress(location);
      Location coords = coordsWrapped[0];
      latitude = double.parse(coords.latitude.toStringAsFixed(3));
      longitude = double.parse(coords.longitude.toStringAsFixed(3));
    } catch (e) {
      //print(e);
    }
  }
}

class GetLocationFromGPS {
  double longitude = 0.0;
  double latitude = 0.0;

  GetLocationFromGPS();

  Future<void> getLocationFromGPS() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      // OpenSettings.openLocationSourceSetting();
      return Future.error(
          'Location permissions are permanently denied, cannot get location data.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    else {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        latitude = double.parse(position.latitude.toStringAsFixed(3));
        longitude = double.parse(position.longitude.toStringAsFixed(3));
      } catch (e) {
        //print(e);
      }
    }
  }
}
