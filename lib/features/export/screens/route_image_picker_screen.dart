import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../convert/models/geotag_data.dart';
import '../services/gpx_export_service.dart';
import '../services/kml_export_service.dart';

class RouteImagePickerScreen extends StatefulWidget {

  final String exportType;

  const RouteImagePickerScreen({

    super.key,
    required this.exportType,

  });

  @override
  State<RouteImagePickerScreen> createState() =>
      _RouteImagePickerScreenState();

}

class _RouteImagePickerScreenState
    extends State<RouteImagePickerScreen> {

  List<File> selectedFiles = [];

  List<GeoTagData> geoList = [];

  bool loading = false;

  int skippedCount = 0;

  ButtonStyle btnStyle() {

    return ElevatedButton.styleFrom(

      elevation: 0,

      backgroundColor:
          Colors.grey.shade100,

      foregroundColor:
          Colors.black87,

      padding:
          const EdgeInsets.symmetric(
              vertical: 14),

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(30),

      ),

    );

  }

  Future<void> pickImages() async {

    final picker = ImagePicker();

    final picked =
        await picker.pickMultiImage();

    if (picked.isEmpty) return;

    setState(() {

      selectedFiles.addAll(

        picked.map((e) => File(e.path)),

      );

    });

  }

  void removeImage(int i) {

    setState(() {

      selectedFiles.removeAt(i);

    });

  }

  void clearAll() {

    setState(() {

      selectedFiles.clear();

    });

  }

  Future<void> processImages() async {

    geoList.clear();

    skippedCount = 0;

    for (var file in selectedFiles) {

      final exif =
          await readExifLatLng(file);

      if (exif == null) {

        skippedCount++;

        continue;

      }

      geoList.add(

        GeoTagData(

          fileName:
              file.path.split("/").last,

          latitude: exif.lat,

          longitude: exif.lng,

          datetime: exif.time,

          address: "",

          timezone: "",

          employeeName: "",

        ),

      );

    }

  }

  Future<void> exportRoute() async {

    if (selectedFiles.isEmpty) {

      showMsg("Select images");

      return;

    }

    setState(() => loading = true);

    await processImages();

    setState(() => loading = false);

    if (geoList.isEmpty) {

      showMsg(
          "No images contain GPS metadata");

      return;

    }

    if (skippedCount > 0) {

      showMsg(
          "$skippedCount images skipped (no GPS)");

    }

    showMapPreview();

  }

  void showMapPreview() {

    final points = geoList

        .map(

          (e) => LatLng(

            e.latitude,

            e.longitude,

          ),

        )

        .toList();

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      builder: (_) {

        return SizedBox(

          height: 500,

          child: Column(

            children: [

              Expanded(

                child: FlutterMap(

                  options: MapOptions(

                    initialCenter:
                        points.first,

                    initialZoom: 15,

                  ),

                  children: [

                    TileLayer(

                      urlTemplate:

                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

                    ),

                    MarkerLayer(

                      markers: points

                          .map(

                            (p) => Marker(

                              point: p,

                              width: 40,

                              height: 40,

                              child:

                                  const Icon(

                                Icons.location_on,

                                color: Colors.red,

                              ),

                            ),

                          )

                          .toList(),

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

                  style: btnStyle(),

                  onPressed: saveFile,

                  child:

                      const Text("Export"),

                ),

              ),

            ],

          ),

        );

      },

    );

  }

  Future<void> saveFile() async {

    Navigator.pop(context);

    if (widget.exportType == "gpx") {

      final file =
          await exportGpx(geoList);

      showMsg(
          "Saved in Converted tab");

    }

    else {

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

                      "Saved in Converted tab");

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

                      "Saved in Converted tab");

                },

                child:
                    const Text("LINE"),

              ),

            ],

          );

        },

      );

    }

  }

  Future<_ExifResult?> readExifLatLng(

      File file) async {

    try {

      final bytes =
          await file.readAsBytes();

      final data =
          await readExifFromBytes(bytes);

      if (!data.containsKey(
              "GPS GPSLatitude") ||

          !data.containsKey(
              "GPS GPSLongitude")) {

        return null;

      }

      final lat =
          parseGps(
              data["GPS GPSLatitude"]);

      final lng =
          parseGps(
              data["GPS GPSLongitude"]);

      final time =

          data["EXIF DateTimeOriginal"]
                  ?.printable ??

              DateTime.now().toString();

      if (lat == null || lng == null) {

        return null;

      }

      return _ExifResult(

        lat: lat,

        lng: lng,

        time: time,

      );

    }

    catch (_) {

      return null;

    }

  }

  double? parseGps(value) {

    try {

      final parts =
          value.values.toList();

      double d =
          parts[0].numerator /
              parts[0].denominator;

      double m =
          parts[1].numerator /
              parts[1].denominator;

      double s =
          parts[2].numerator /
              parts[2].denominator;

      return d + (m / 60) + (s / 3600);

    }

    catch (_) {

      return null;

    }

  }

  void showMsg(String msg) {

    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(

        content: Text(msg),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(

            widget.exportType.toUpperCase()),

        actions: [

          if (selectedFiles.isNotEmpty)

            IconButton(

              icon:
                  const Icon(Icons.delete),

              onPressed: clearAll,

            ),

        ],

      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          children: [

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                Text(

                  "Images (${selectedFiles.length})",

                  style:
                      const TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                ElevatedButton.icon(

                  onPressed: pickImages,

                  icon:
                      const Icon(Icons.add),

                  label:
                      const Text("Add"),

                ),

              ],

            ),

            const SizedBox(height: 10),

            Expanded(

              child: selectedFiles.isEmpty

                  ? const Center(

                      child:
                          Text("No images"),

                    )

                  : GridView.builder(

                      itemCount:
                          selectedFiles.length,

                      gridDelegate:

                          const SliverGridDelegateWithFixedCrossAxisCount(

                        crossAxisCount: 3,

                        crossAxisSpacing: 8,

                        mainAxisSpacing: 8,

                      ),

                      itemBuilder: (_, i) {

                        return Stack(

                          children: [

                            Image.file(

                              selectedFiles[i],

                              fit:
                                  BoxFit.cover,

                            ),

                            Positioned(

                              right: 0,

                              child:
                                  GestureDetector(

                                onTap: () =>
                                    removeImage(i),

                                child: const Icon(

                                  Icons.close,

                                  color: Colors.red,

                                ),

                              ),

                            ),

                          ],

                        );

                      },

                    ),

            ),

            const SizedBox(height: 10),

            ElevatedButton(

              style: btnStyle(),

              onPressed:
                  loading
                      ? null
                      : exportRoute,

              child: Text(

                loading
                    ? "Processing..."
                    : "Next",

              ),

            ),

          ],

        ),

      ),

    );

  }

}

class _ExifResult {

  final double lat;

  final double lng;

  final String time;

  _ExifResult({

    required this.lat,

    required this.lng,

    required this.time,

  });

}