
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class LocationService {

  Future<Map<String, dynamic>> getLocationDetails() async {

    // Permission check
    LocationPermission permission =
        await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    // 1. Try last known location (instant)
    Position? lastPosition =
        await Geolocator.getLastKnownPosition();

    Position position;

    if (lastPosition != null) {
      position = lastPosition;
    } else {
      // 2. Fallback to fresh GPS
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    // 3. Try getting a better (fresh) position in background
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).then((newPos) {
      // You can update UI or cache here
    });

    String address = "Address unavailable";

    try {
      // 4. Try reverse geocoding (only works online)
      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        address =
            "${place.street ?? ''}, "
            "${place.locality ?? ''}, "
            "${place.administrativeArea ?? ''}, "
            "${place.country ?? ''}";
      }

    } catch (e) {
      // Offline fallback (silent fail)
      print("Geocoding failed: $e");
    }

    DateTime now = DateTime.now();

    return {
      "lat": position.latitude,
      "lng": position.longitude,
      "accuracy": position.accuracy,
      "address": address,
      "dateTime":
          DateFormat("yyyy-MM-dd HH:mm:ss").format(now),
      "timezone": now.timeZoneName,
      "utcTime": now.toUtc().toString(),
    };
  }
}