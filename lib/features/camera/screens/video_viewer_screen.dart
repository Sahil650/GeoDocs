
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/location_overlay_card.dart';
import '../services/geotag_preview_service.dart';


class VideoViewerScreen extends StatefulWidget {

  final String videoPath;
  final String address;
  final double lat;
  final double lng;
  final String dateTime;
  final String timezone;

  const VideoViewerScreen({

    super.key,

    required this.videoPath,
    required this.address,
    required this.lat,
    required this.lng,
    required this.dateTime,
    required this.timezone,

  });

  @override
  State<VideoViewerScreen> createState() =>
      _VideoViewerScreenState();

}

class _VideoViewerScreenState
    extends State<VideoViewerScreen> {

  late VideoPlayerController controller;

  bool initialized = false;
  bool showControls = true;

  /// Whether the geotag + minimap overlay card is visible
  bool showOverlay = true;

  bool exporting = false;

  Timer? hideTimer;

  @override
  void initState() {

    super.initState();

    controller =
        VideoPlayerController.file(File(widget.videoPath))
          ..initialize().then((_) {

            setState(() => initialized = true);

            controller.play();

            startHideTimer();

          });

    controller.addListener(() => setState(() {}));

  }

  // ─── Control helpers ────────────────────────────────────────

  void startHideTimer() {

    hideTimer?.cancel();

    hideTimer = Timer(

      const Duration(seconds: 3),

      () => setState(() => showControls = false),

    );

  }

  void toggleControls() {

    setState(() => showControls = true);

    startHideTimer();

  }

  /// Single tap: show/hide playback controls.
  /// Double-tap: show/hide the geotag overlay.
  void toggleOverlay() => setState(() => showOverlay = !showOverlay);

  void togglePlay() {

    controller.value.isPlaying
        ? controller.pause()
        : controller.play();

    startHideTimer();

  }

  // ─── Actions ────────────────────────────────────────────────

  Future deleteVideo() async {

    await controller.pause();

    await File(widget.videoPath).delete();

    if (mounted) Navigator.pop(context);

  }

  Future shareVideo() async {

    setState(() => exporting = true);

    // GeoTagPreviewService now renders minimap + text side-by-side
    final previewImage =
        await GeoTagPreviewService.createPreview(

      address: widget.address,
      lat: widget.lat,
      lng: widget.lng,
      dateTime: widget.dateTime,
      timezone: widget.timezone,

    );

    setState(() => exporting = false);

    await SharePlus.instance.share(

      ShareParams(

        files: [
          XFile(widget.videoPath),
          XFile(previewImage),
        ],

        text: "Geo Tagged Video",

      ),

    );

  }

  // ─── Helpers ────────────────────────────────────────────────

  String format(Duration d) {

    String two(int n) => n.toString().padLeft(2, "0");

    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";

  }

  @override
  void dispose() {

    hideTimer?.cancel();

    controller.dispose();

    super.dispose();

  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      body: GestureDetector(

        onTap: toggleControls,
        onDoubleTap: toggleOverlay,       // double-tap hides/shows geotag card

        child: Stack(

          children: [

            // ── Video player ──────────────────────────────────
            Center(

              child: initialized

                  ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )

                  : const CircularProgressIndicator(),

            ),

            // ── Play icon when paused ─────────────────────────
            if (initialized && !controller.value.isPlaying)

              Center(

                child: GestureDetector(

                  onTap: togglePlay,

                  child: const Icon(
                    Icons.play_circle_fill,
                    size: 80,
                    color: Colors.white70,
                  ),

                ),

              ),

            // ── Top bar: back / share / delete ───────────────
            Positioned(

              top: 40,
              left: 10,
              right: 10,

              child: Row(

                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [

                  IconButton(

                    icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white),

                    onPressed: () => Navigator.pop(context),

                  ),

                  Row(

                    children: [

                      // Overlay toggle hint button
                      IconButton(

                        icon: Icon(
                          showOverlay
                              ? Icons.layers
                              : Icons.layers_clear,
                          color: Colors.white70,
                        ),

                        tooltip: "Toggle geotag overlay",

                        onPressed: toggleOverlay,

                      ),

                      IconButton(

                        icon: const Icon(
                            Icons.share,
                            color: Colors.white),

                        onPressed: shareVideo,

                      ),

                      IconButton(

                        icon: const Icon(
                            Icons.delete,
                            color: Colors.red),

                        onPressed: deleteVideo,

                      ),

                    ],

                  ),

                ],

              ),

            ),

            // ── Seek / duration controls ─────────────────────
            if (initialized && showControls)

              Positioned(

                // Push the slider above the overlay card (145 h + 16 bottom padding + some gap)
                bottom: showOverlay ? 175 : 20,

                left: 20,
                right: 20,

                child: Column(

                  children: [

                    Slider(

                      value: controller.value.position
                          .inSeconds
                          .toDouble(),

                      max: controller.value.duration
                          .inSeconds
                          .toDouble()
                          .clamp(0.001, double.infinity),

                      onChanged: (value) {

                        controller.seekTo(
                            Duration(seconds: value.toInt()));

                      },

                    ),

                    Row(

                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        Text(
                          format(controller.value.position),
                          style: const TextStyle(
                              color: Colors.white),
                        ),

                        Text(
                          format(controller.value.duration),
                          style: const TextStyle(
                              color: Colors.white),
                        ),

                      ],

                    ),

                  ],

                ),

              ),

            // ── Geotag + MiniMap overlay card ────────────────
            //
            // LocationOverlayCard already embeds MiniMapWidget
            // on the left side alongside the address / lat-lng /
            // datetime text on the right.
            //
            AnimatedSlide(

              duration: const Duration(milliseconds: 300),

              curve: Curves.easeInOut,

              offset: showOverlay
                  ? Offset.zero
                  : const Offset(0, 1.5),

              child: AnimatedOpacity(

                duration: const Duration(milliseconds: 300),

                opacity: showOverlay ? 1.0 : 0.0,

                child: Positioned(

                  bottom: 10,
                  left: 12,
                  right: 12,

                  child: LocationOverlayCard(

                    address: widget.address,
                    lat: widget.lat,
                    lng: widget.lng,
                    dateTime: widget.dateTime,
                    timezone: widget.timezone,
                    // isRecording defaults to false — no red border

                  ),

                ),

              ),

            ),

            // ── Export loading spinner ────────────────────────
            if (exporting)

              Container(

                color: Colors.black54,

                child: const Center(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      CircularProgressIndicator(
                          color: Colors.white),

                      SizedBox(height: 16),

                      Text(

                        "Generating geotag preview…",

                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14),

                      ),

                    ],

                  ),

                ),

              ),

          ],

        ),

      ),

    );

  }

}