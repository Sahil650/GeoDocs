
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MiniMapWidget extends StatelessWidget {

  final double lat;
  final double lng;

  const MiniMapWidget({
    super.key,
    required this.lat,
    required this.lng,
  });

  Future<void> openMap() async {

    final url =
        "https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng";

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: openMap,

      child: FlutterMap(

        options: MapOptions(

          initialCenter: LatLng(lat, lng),

          initialZoom: 16,

          interactionOptions: const InteractionOptions(

            flags: InteractiveFlag.drag |
                   InteractiveFlag.pinchZoom |
                   InteractiveFlag.doubleTapZoom,

          ),

        ),

        children: [

          TileLayer(

            urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

            userAgentPackageName:
                'com.geofusion.app',

          ),

          MarkerLayer(

            markers: [

              Marker(

                point: LatLng(lat, lng),

                width: 30,

                height: 30,

                child: const Icon(

                  Icons.location_pin,

                  color: Colors.red,

                  size: 30,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }

}