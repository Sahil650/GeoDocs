import 'package:flutter/material.dart';

class GeoTagOverlay extends StatelessWidget {

  final String lat;
  final String lng;
  final String address;
  final String date;
  final String time;

  const GeoTagOverlay({

    super.key,

    required this.lat,
    required this.lng,
    required this.address,
    required this.date,
    required this.time,

  });

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color: Colors.black.withOpacity(.55),

        borderRadius: BorderRadius.circular(10),

      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        mainAxisSize: MainAxisSize.min,

        children: [

          Text(
            "Latitude: $lat",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),

          Text(
            "Longitude: $lng",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Address:",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          Text(
            address,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "Date: $date",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),

          Text(
            "Time: $time",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),

        ],

      ),

    );

  }

}