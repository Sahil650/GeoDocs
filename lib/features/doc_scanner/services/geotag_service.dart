import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GeoData {

  final String address;
  final double lat;
  final double lng;

  GeoData({

    required this.address,
    required this.lat,
    required this.lng,

  });

}

class GeotagService {

  static Future<GeoData> getLocation() async {

    /// check permission
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {

      permission =
      await Geolocator.requestPermission();

    }

    /// get position
    Position pos =
    await Geolocator.getCurrentPosition(

      desiredAccuracy:
      LocationAccuracy.high,

    );

    /// convert lat lng to address
    List<Placemark> place =

    await placemarkFromCoordinates(

      pos.latitude,
      pos.longitude,

    );

    Placemark p = place.first;

    String address =

        "${p.street}, "
        "${p.locality}, "
        "${p.administrativeArea}, "
        "${p.country}";

    return GeoData(

      address: address,
      lat: pos.latitude,
      lng: pos.longitude,

    );

  }

}