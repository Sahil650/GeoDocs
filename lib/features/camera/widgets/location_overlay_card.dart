
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mini_map_widget.dart';

class LocationOverlayCard extends StatefulWidget {

  final String address;
  final double lat;
  final double lng;
  final String dateTime;
  final String timezone;
  final bool isRecording;

  const LocationOverlayCard({

    super.key,
    required this.address,
    required this.lat,
    required this.lng,
    required this.dateTime,
    required this.timezone,
    this.isRecording = false,

  });

  @override
  State<LocationOverlayCard> createState() => _LocationOverlayCardState();
}

class _LocationOverlayCardState extends State<LocationOverlayCard> {

  String? logoPath;

  @override
  void initState() {
    super.initState();
    loadLogo();
  }

  /// load saved logo
  Future<void> loadLogo() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      logoPath = prefs.getString("watermark");
    });

  }

  /// pick new logo
  // Future<void> pickLogo() async {

  //   final picker = ImagePicker();

  //   final file = await picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 100,
  //   );

  //   if (file == null) return;

  //   final prefs = await SharedPreferences.getInstance();

  //   await prefs.setString("watermark", file.path);

  //   setState(() {
  //     logoPath = file.path;
  //   });

  // }

  String _formatDate(String rawDate) {

    try {

      final dt = DateTime.parse(rawDate);

      String twoDigits(int n) =>
          n.toString().padLeft(2, '0');

      return "${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)} "
          "${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}";

    } catch (e) {

      return rawDate;

    }

  }

  @override
  Widget build(BuildContext context) {

    return Container(

      height: 145,

      decoration: BoxDecoration(

        color: Colors.black.withValues(alpha: 0.85),

        borderRadius: BorderRadius.circular(16),

        border: widget.isRecording
            ? Border.all(
                color: Colors.red.withValues(alpha: 0.7),
                width: 1.2,
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.6),

            blurRadius: 14,

            offset: const Offset(0, 6),

          ),

        ],

      ),

      child: ClipRRect(

        borderRadius: BorderRadius.circular(16),

        child: Stack(

          children: [

            Row(

              children: [

                /// MAP
                SizedBox(

                  width: 115,

                  height: 145,

                  child: Stack(

                    children: [

                      MiniMapWidget(
                        lat: widget.lat,
                        lng: widget.lng,
                      ),

                      if (widget.isRecording)

                        Positioned(

                          top: 6,
                          left: 6,

                          child: Container(

                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2),

                            decoration: BoxDecoration(

                              color: Colors.red,

                              borderRadius:
                                  BorderRadius.circular(4),

                            ),

                            child: const Text(

                              "LIVE",

                              style: TextStyle(

                                color: Colors.white,

                                fontSize: 8,

                                fontWeight:
                                    FontWeight.bold,

                              ),

                            ),

                          ),

                        ),

                    ],

                  ),

                ),

                /// TEXT SECTION
                Expanded(

                  child: Padding(

                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        /// ADDRESS
                        Row(

                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            const Padding(

                              padding:
                                  EdgeInsets.only(top: 2),

                              child: Icon(
                                Icons.place,
                                size: 15,
                                color: Colors.redAccent,
                              ),

                            ),

                            const SizedBox(width: 6),

                            Expanded(

                              child: Text(

                                widget.address,

                                maxLines: 2,

                                overflow:
                                    TextOverflow.ellipsis,

                                style:
                                    const TextStyle(

                                  color: Colors.white,

                                  fontSize: 13,

                                  fontWeight:
                                      FontWeight.w600,

                                  height: 1.3,

                                ),

                              ),

                            ),

                          ],

                        ),

                        const SizedBox(height: 10),

                        /// LAT LNG
                        Row(

                          children: [

                            const Icon(
                              Icons.gps_fixed,
                              size: 13,
                              color: Colors.blueAccent,
                            ),

                            const SizedBox(width: 6),

                            Text(

                              widget.lat.toStringAsFixed(6),

                              style: TextStyle(

                                color: Colors.white
                                    .withValues(alpha: 0.85),

                                fontSize: 11,

                                fontFamily:
                                    'monospace',

                              ),

                            ),

                            const SizedBox(width: 12),

                            Text(

                              widget.lng.toStringAsFixed(6),

                              style: TextStyle(

                                color: Colors.white
                                    .withValues(alpha: 0.85),

                                fontSize: 11,

                                fontFamily:
                                    'monospace',

                              ),

                            ),

                          ],

                        ),

                        const SizedBox(height: 6),

                        /// TIME
                        Row(

                          children: [

                            const Icon(
                              Icons.access_time,
                              size: 13,
                              color: Colors.white70,
                            ),

                            const SizedBox(width: 6),

                            Text(

                              _formatDate(widget.dateTime),

                              style: TextStyle(

                                color: Colors.white
                                    .withValues(alpha: 0.75),

                                fontSize: 10,

                                fontFamily:
                                    'monospace',

                              ),

                            ),

                          ],

                        ),

                      ],

                    ),

                  ),

                ),

              ],

            ),

            // /// LOGO WATERMARK (BOTTOM RIGHT CLICKABLE)
            // Positioned(

            //   bottom: 6,
            //   right: 6,

            //   child: GestureDetector(

            //     onTap: pickLogo,

            //     child: Container(

            //       height: 34,
            //       width: 34,

            //       padding: const EdgeInsets.all(4),

            //       decoration: BoxDecoration(

            //         color: Colors.white.withValues(alpha: 0.08),

            //         borderRadius: BorderRadius.circular(6),

            //         border: Border.all(
            //           color: Colors.white24,
            //         ),

            //       ),

            //       child: logoPath == null

            //           ? const Icon(
            //               Icons.add_photo_alternate,
            //               size: 18,
            //               color: Colors.white70,
            //             )

            //           : Image.file(
            //               File(logoPath!),
            //               fit: BoxFit.cover,
            //             ),

            //     ),

            //   ),

            // ),

          ],

        ),

      ),

    );

  }

}