import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  static Future<Map<String,dynamic>>
      getLocation() async {

    Position pos =
        await Geolocator.getCurrentPosition();

    List<Placemark> placemarks =

        await placemarkFromCoordinates(

      pos.latitude,
      pos.longitude,
    );

    final place = placemarks.first;

    return {

      "lat": pos.latitude,

      "lng": pos.longitude,

      "address":

          "${place.street}, "

          "${place.locality}, "

          "${place.country}",
    };
  }
}