import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GetLocation {
  late String location;
  double longitude = 0.0;
  double latitude = 0.0;

  GetLocation({required this.location});

  Future<void> getLocationFromUserInput() async {
    try {
      List what = await locationFromAddress(location);
      Location coords = what[0];
      latitude = double.parse(coords.latitude.toStringAsFixed(3));
      longitude = double.parse(coords.longitude.toStringAsFixed(3));
    } catch (e) {
      print(e);
    }
  }
}
