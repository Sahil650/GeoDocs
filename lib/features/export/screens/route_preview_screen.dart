import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../convert/models/geotag_data.dart';
import '../services/gpx_export_service.dart';
import '../services/kml_export_service.dart';

class RoutePreviewScreen extends StatelessWidget {

  final List<GeoTagData> geoList;

  final String exportType;

  const RoutePreviewScreen({

    super.key,

    required this.geoList,

    required this.exportType,

  });

  @override
  Widget build(BuildContext context) {

    final points = geoList

        .map(

          (e) => LatLng(

            e.latitude,

            e.longitude,

          ),

        )

        .toList();

    return Scaffold(

      appBar: AppBar(

        title: const Text("Preview Route"),

      ),

      body: Column(

        children: [

          Expanded(

            child: FlutterMap(

              options: MapOptions(

                initialCenter: points.first,

                initialZoom: 15,

              ),

              children: [

                TileLayer(

                  urlTemplate:

                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

                ),

                MarkerLayer(

                  markers: points.map(

                    (p) {

                      return Marker(

                        point: p,

                        width: 40,

                        height: 40,

                        child:

                            const Icon(

                          Icons.location_on,

                          color: Colors.red,

                        ),

                      );

                    },

                  ).toList(),

                ),

                PolylineLayer(

                  polylines: [

                    Polyline(

                      points: points,

                      strokeWidth: 4,

                    ),

                  ],

                ),

              ],

            ),

          ),

          Padding(

            padding:

                const EdgeInsets.all(12),

            child: ElevatedButton(

              onPressed: () async {

                if (exportType == "gpx") {

                  final file =

                      await exportGpx(geoList);

                  showMsg(

                    context,

                    "GPX saved",

                  );

                }

                else {

                  showKmlDialog(

                      context);

                }

              },

              child: const Text("Export"),

            ),

          ),

        ],

      ),

    );

  }

  void showKmlDialog(

      BuildContext context) {

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          title:

              const Text("KML type"),

          actions: [

            TextButton(

              onPressed: () async {

                Navigator.pop(context);

                await exportKml(

                  geoList,

                  asLine: false,

                );

                showMsg(

                  context,

                  "KML POINT saved",

                );

              },

              child:

                  const Text("POINT"),

            ),

            TextButton(

              onPressed: () async {

                Navigator.pop(context);

                await exportKml(

                  geoList,

                  asLine: true,

                );

                showMsg(

                  context,

                  "KML LINE saved",

                );

              },

              child:

                  const Text("LINE"),

            ),

          ],

        );

      },

    );

  }

  void showMsg(

      BuildContext context,

      String msg,

  ) {

    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(

        content: Text(msg),

      ),

    );

  }

}