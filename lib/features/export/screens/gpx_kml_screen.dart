import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';

import '../../convert/models/geotag_data.dart';
import '../services/gpx_export_service.dart';
import '../services/kml_export_service.dart';

class GpxKmlScreen extends StatefulWidget {

  final String type;

  const GpxKmlScreen({

    super.key,

    required this.type,
  });

  @override
  State<GpxKmlScreen> createState() =>
      _GpxKmlScreenState();
}

class _GpxKmlScreenState
    extends State<GpxKmlScreen> {

  List<File> selectedFiles = [];

  List<GeoTagData> geoList = [];

  int skippedCount = 0;

  bool loading = false;

  ButtonStyle softButtonStyle() {

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

  /// pick images
  Future<void> pickImages() async {

  final picker = ImagePicker();

  final picked =
      await picker.pickMultiImage();

  if (picked.isEmpty) return;

  int skipped = 0;

  for (var file in picked) {

    final f = File(file.path);

    /// prevent duplicate image
    if (selectedFiles.any(
        (e) => e.path == f.path)) {

      continue;
    }

    final gps =
        await readGPS(f);

    if (gps != null) {

      selectedFiles.add(f);

      geoList.add(

        GeoTagData(

          fileName: file.name,

          latitude: gps.lat,

          longitude: gps.lng,

          datetime: gps.time,

          address: "",

          timezone: "",

          employeeName: "",
        ),
      );

    } else {

      skipped++;
    }
  }

  setState(() {});

  if (skipped > 0) {

    showMsg(
        "$skipped images skipped (no GPS metadata)");
  }
}

  /// read GPS metadata
  Future<_GPS?> readGPS(
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
          convertToDegree(
              data["GPS GPSLatitude"]);

      final lng =
          convertToDegree(
              data["GPS GPSLongitude"]);

      final latRef =
          data["GPS GPSLatitudeRef"]
              ?.printable;

      final lngRef =
          data["GPS GPSLongitudeRef"]
              ?.printable;

      double finalLat =
          latRef == "S" ? -lat : lat;

      double finalLng =
          lngRef == "W" ? -lng : lng;

      final time =
          data["EXIF DateTimeOriginal"]
                  ?.printable ??
              DateTime.now().toString();

      return _GPS(

        lat: finalLat,

        lng: finalLng,

        time: time,
      );

    } catch (_) {

      return null;
    }
  }

  double convertToDegree(value) {

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

  void removeImage(int index) {

    setState(() {

      selectedFiles.removeAt(index);

      geoList.removeAt(index);
    });
  }

  void clearAll() {

    setState(() {

      selectedFiles.clear();

      geoList.clear();
    });
  }

  /// export
  Future<void> exportFile() async {

    if (geoList.isEmpty) {

      showMsg(
          "No GPS images selected");

      return;
    }

    setState(() => loading = true);

    try {

      if (widget.type == "gpx") {

        await exportGpx(geoList);

      } else {

        bool asLine =
            await showDialog(

          context: context,

          builder: (_) =>
              AlertDialog(

            title:
                const Text("KML Type"),

            actions: [

              TextButton(

                onPressed: () =>
                    Navigator.pop(
                        context, false),

                child:
                    const Text("POINT"),
              ),

              TextButton(

                onPressed: () =>
                    Navigator.pop(
                        context, true),

                child:
                    const Text("LINE"),
              ),
            ],
          ),
        ) ?? true;

        await exportKml(

          geoList,

          asLine: asLine,
        );
      }

      showMsg(
          "Saved in Converted tab");

    } catch (e) {

      showMsg("Export failed");
    }

    setState(() => loading = false);
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

        title:
            Text(widget.type.toUpperCase()),

        actions: [

          if (selectedFiles.isNotEmpty)

            IconButton(

              icon:
                  const Icon(Icons.delete),

              onPressed: clearAll,
            ),
        ],
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                Text(

                  "Images (${selectedFiles.length})",

                  style:
                      const TextStyle(

                    fontSize: 16,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                ElevatedButton.icon(

                  onPressed: pickImages,

                  icon: const Icon(
                      Icons.add_photo_alternate),

                  label:
                      const Text("Add Images"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (selectedFiles.isEmpty)

              Container(

                height: 180,

                alignment:
                    Alignment.center,

                decoration:

                    BoxDecoration(

                  color: Colors.grey[300],

                  borderRadius:
                      BorderRadius.circular(
                          12),
                ),

                child: const Text(
                    "No GPS Images Selected"),
              )

            else

              SizedBox(

                height: 200,

                child: GridView.builder(

                  scrollDirection:
                      Axis.horizontal,

                  gridDelegate:

                      const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount: 1,

                    mainAxisSpacing: 8,
                  ),

                  itemCount:
                      selectedFiles.length,

                  itemBuilder:
                      (context, index) {

                    return Stack(

                      children: [

                        ClipRRect(

                          borderRadius:
                              BorderRadius.circular(
                                  8),

                          child: Image.file(

                            selectedFiles[index],

                            width: 150,

                            height: 150,

                            fit: BoxFit.cover,
                          ),
                        ),

                        Positioned(

                          top: 4,

                          right: 4,

                          child:
                              GestureDetector(

                            onTap: () =>
                                removeImage(
                                    index),

                            child:
                                Container(

                              padding:

                                  const EdgeInsets.all(
                                      2),

                              decoration:

                                  const BoxDecoration(

                                color: Colors.red,

                                shape:
                                    BoxShape.circle,
                              ),

                              child:
                                  const Icon(

                                Icons.close,

                                size: 16,

                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 15),

            Text(

              "GPS images: ${geoList.length}",

              style:
                  const TextStyle(

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(

              style:
                  softButtonStyle(),

              onPressed:
                  loading
                      ? null
                      : exportFile,

              icon: loading

                  ? const SizedBox(

                      width: 18,

                      height: 18,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )

                  : const Icon(Icons.map),

              label: Text(

                loading
                    ? "Exporting..."

                    : "Export ${widget.type.toUpperCase()}",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GPS {

  final double lat;

  final double lng;

  final String time;

  _GPS({

    required this.lat,

    required this.lng,

    required this.time,
  });
}