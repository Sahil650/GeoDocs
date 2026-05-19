import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/camera_overlay_ui.dart';
import '../widgets/video_overlay_ui.dart';
// import '../widgets/compass_widget.dart';
import '../widgets/location_overlay_card.dart';
import '../services/video_overlay_service.dart';
import '../services/geotag_preview_service.dart';
import '../services/media_scanner_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/storage_service.dart';

enum CameraMode { photo, video }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;

  List<CameraDescription> cameras = [];
int cameraIndex = 0;
  Timer? _clockTimer;

  bool loadingCamera = true;
  bool loadingLocation = true;
  bool isProcessing = false;
  double _videoProgress = 0.0;  // 0.0 → 1.0 during FFmpeg overlay burn
  bool _isBurningOverlay = false;
  bool hasPermission = true; // Assume true until initialization fails
  String? cameraError;

  double? lat;
  double? lng;

  String address = "";
  String dateTime = "";
  String timezone = "";
  String? watermarkPath;

  FlashMode flashMode = FlashMode.off;
  double zoom = 1;

  String? lastImagePath;
  String? lastVideoPath;
  final GlobalKey _boundaryKey = GlobalKey();

  CameraMode currentMode = CameraMode.photo;
  bool isRecording = false;
  Duration recordingDuration = Duration.zero;
  DateTime? recordingStartTime;

  Timer? _durationTimer;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    initAll();
  }
  void _startClockTimer() {

  _clockTimer?.cancel();

  _clockTimer =
      Timer.periodic(const Duration(seconds: 1), (timer) {

    final now = DateTime.now();

    setState(() {

      dateTime = now.toIso8601String();

    });

  });

}

Future loadWatermark() async {

  final prefs =
      await SharedPreferences.getInstance();

  String? savedPath =
      prefs.getString("watermark");

  /// if user selected logo
  if (savedPath != null &&
      File(savedPath).existsSync()) {

    watermarkPath = savedPath;

  }

  /// otherwise load default logo
  else {

    final bytes =
        await rootBundle.load(
      "assets/watermark/default_logo.png",
    );

    final dir =
        await getTemporaryDirectory();

    final file =
        File("${dir.path}/default_logo.png");

    /// create file only once
    if (!await file.exists()) {

      await file.writeAsBytes(
          bytes.buffer.asUint8List());

    }

    /// save default path
    await prefs.setString(
        "watermark", file.path);

    watermarkPath = file.path;

  }

  setState(() {});

}

  Future initAll() async {
    await startCamera();
    await _loadLastMedia();
    await loadLocation();
    await loadWatermark();

    _startClockTimer();
  }

  Future startCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          cameraError = "No cameras found on device";
          loadingCamera = false;
        });
        return;
      }

      controller = CameraController(
        cameras[cameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller!.initialize();
      if (mounted) setState(() {
        loadingCamera = false;
        hasPermission = true;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          loadingCamera = false;
          if (e.code == 'CameraAccessDenied') {
            hasPermission = false;
          } else {
            cameraError = e.description ?? e.code;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loadingCamera = false;
          cameraError = e.toString();
        });
      }
    }
  }


Future switchCamera() async {

  if (cameras.length < 2) return;

  cameraIndex = cameraIndex == 0 ? 1 : 0;

  await controller?.dispose();

  controller = CameraController(
    cameras[cameraIndex],
    ResolutionPreset.high,
    enableAudio: true,
  );

  await controller!.initialize();

  setState(() {});
}

  Future<void> _loadLastMedia() async {
    final folder = await StorageService.getPhotoDirectory();
    if (!await folder.exists()) return;
    try {
      final entities = await folder.list().toList();
      
      final images = entities.where((e) => e.path.endsWith('.jpg') || e.path.endsWith('.png')).toList();
      if (images.isNotEmpty) {
        images.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        lastImagePath = images.first.path;
      }

      final videos = entities.where((e) => e.path.endsWith('.mp4')).toList();
      if (videos.isNotEmpty) {
        videos.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        lastVideoPath = videos.first.path;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading startup media: $e");
    }
  }

  Future loadLocation() async {
    try {
      final data = await LocationService().getLocationDetails();
      lat = data["lat"];
      lng = data["lng"];
      address = data["address"];
      dateTime = data["dateTime"];
      timezone = "${data["timezone"]} | UTC ${data["utcTime"]}";
    } catch (e) {
      address = "Location Unavailable";
      dateTime = DateTime.now().toString();
    } finally {
      if (mounted) setState(() => loadingLocation = false);
    }
  }

  void switchMode(CameraMode mode) {
    if (mode == currentMode) return;
    if (isRecording) stopVideoRecording();
    setState(() => currentMode = mode);
  }

  Future startVideoRecording() async {
    if (controller == null || !controller!.value.isInitialized) return;
    await loadLocation();

    try {
      await controller!.startVideoRecording();
      setState(() {
        isRecording = true;
        recordingStartTime = DateTime.now();
        recordingDuration = Duration.zero;
      });
      _startDurationTimer();
      _startLocationUpdateTimer();
    } catch (e) {
      debugPrint("Error starting video recording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start: $e")),
        );
      }
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isRecording) return timer.cancel();
      setState(() => recordingDuration = DateTime.now().difference(recordingStartTime!));
    });
  }

  void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isRecording) return timer.cancel();
      loadLocation();
      setState(() {});
    });
  }

  Future stopVideoRecording() async {
    if (!isRecording || controller == null) return;
 
    _durationTimer?.cancel();
    _locationUpdateTimer?.cancel();
 
    setState(() => isProcessing = true);
 
    try {
      // 1. Stop camera — raw temp .mp4
      final videoFile = await controller!.stopVideoRecording();
      final rawPath   = videoFile.path;
 
      // 2. Prepare output folder
      final folder = await StorageService.getPhotoDirectory();
      if (!await folder.exists()) await folder.create(recursive: true);
 
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final latStr    = lat?.toStringAsFixed(4).replaceAll('.', '_') ?? "0_0000";
      final lngStr    = lng?.toStringAsFixed(4).replaceAll('.', '_') ?? "0_0000";
      final finalPath = "${folder.path}/VIDEO_${timestamp}_${latStr}_$lngStr.mp4";
 
      // Use a temp path for the muxer output (different from input)
      final tempDir    = await getTemporaryDirectory();
      final outputPath = "${tempDir.path}/VIDEO_overlay_$timestamp.mp4";
 
      // 3. Render geotag card PNG (minimap + address + coords)
      final overlayPng = await GeoTagPreviewService.createPreview(
        address:  address,
        lat:      lat ?? 0,
        lng:      lng ?? 0,
        dateTime: dateTime,
        timezone: timezone,
      );
 
      // 4. Burn overlay via FFmpeg platform channel (with progress)
      String savedPath;
      bool overlayApplied = false;
      try {
        // Subscribe to progress stream before starting FFmpeg
        setState(() { _isBurningOverlay = true; _videoProgress = 0.0; });
        final progressSub = VideoOverlayService.progressStream.listen((p) {
          if (mounted) setState(() => _videoProgress = p);
        });

        try {
          await VideoOverlayService.burnOverlay(
            inputVideoPath:  rawPath,
            overlayPngPath:  overlayPng,
            outputVideoPath: outputPath,
            lat: lat ?? 0.0,
            lng: lng ?? 0.0,
          );
          overlayApplied = true;
        } finally {
          await progressSub.cancel();
          if (mounted) setState(() { _isBurningOverlay = false; _videoProgress = 0.0; });
        }

        // Move muxed file to final gallery location
        await File(outputPath).copy(finalPath);
        await File(outputPath).delete().catchError((_) {});
        await File(rawPath).delete().catchError((_) {});
        savedPath = finalPath;
      } catch (e) {
        // Graceful fallback: save raw video without overlay
        debugPrint("burnOverlay failed ($e) — saving raw video");
        if (mounted) setState(() { _isBurningOverlay = false; _videoProgress = 0.0; });
        await File(rawPath).copy(finalPath);
        await File(rawPath).delete().catchError((_) {});
        savedPath = finalPath;
      }

      // 5. Save geo sidecar JSON
      await _saveGeoSidecarFile(savedPath);

      // 6. Notify Android MediaStore → file appears in gallery immediately
      await MediaScannerService.scanFile(savedPath);

      setState(() {
        lastVideoPath = savedPath;
        isRecording   = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              overlayApplied
                ? "Video saved with geotag overlay ✓"
                : "Video saved (overlay skipped — raw video)",
            ),
          ),
        );
      }
 
    } catch (e) {
      debugPrint("stopVideoRecording error: $e");
      setState(() => isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving video: $e")),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // FIXED: Save to App Internal Directory so Android doesn't block it
  Future _saveGeoSidecarFile(String videoPath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final videoFileName = videoPath.split('/').last.replaceAll('.mp4', '');
      final sidecarPath = "${dir.path}/$videoFileName.geo.json";
      
      final geoData = {
        "videoPath": videoPath,
        "latitude": lat,
        "longitude": lng,
        "address": address,
        "dateTime": dateTime,
        "timezone": timezone,
        "recordingDuration": recordingDuration.inSeconds,
        "createdAt": DateTime.now().toIso8601String(),
      };
      await File(sidecarPath).writeAsString(jsonEncode(geoData));
    } catch (e) {
      debugPrint("Error saving geo sidecar: $e");
    }
  }

  void toggleRecording() {
    isRecording ? stopVideoRecording() : startVideoRecording();
  }

  Future capturePhoto() async {

  await loadLocation();

  final image = await controller!.takePicture();

  if (mounted) {
    setState(() {
      isProcessing = true;
      lastImagePath = image.path;
    });
  }

  await Future.delayed(const Duration(milliseconds: 400));

  try {

    final originalBytes =
        await File(image.path).readAsBytes();

    final originalImage =
        await decodeImageFromList(originalBytes);

    RenderRepaintBoundary boundary =
        _boundaryKey.currentContext!
            .findRenderObject()
        as RenderRepaintBoundary;

    ui.Image overlayImage =
        await boundary.toImage(pixelRatio: 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    /// draw camera photo
    canvas.drawImage(
        originalImage,
        Offset.zero,
        paint);

    /// scale overlay correctly
    final srcRect = Rect.fromLTWH(
      0,
      0,
      overlayImage.width.toDouble(),
      overlayImage.height.toDouble(),
    );

    final dstRect = Rect.fromLTWH(
      0,
      0,
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );

    canvas.drawImageRect(
      overlayImage,
      srcRect,
      dstRect,
      paint,
    );

    /// ADD WATERMARK INTO IMAGE
/// ADD WATERMARK INTO IMAGE
try {
  if (watermarkPath != null && File(watermarkPath!).existsSync()) {

    final watermarkBytes = await File(watermarkPath!).readAsBytes();
    final codec = await ui.instantiateImageCodec(watermarkBytes);
    final frame = await codec.getNextFrame();
    final watermarkImage = frame.image;

    // Use same ratio as preview UI
    double logoSize = originalImage.width * 0.09;

    // right: 10px on screen → scale to image space
    final double screenW = MediaQuery.of(context).size.width;
    final double rightMargin = (10.0 / screenW) * originalImage.width;

    // bottom: screen uses 0.12 * screenHeight above the bottom
    // Mirror that in image space
    final double bottomMargin = originalImage.height * 0.003;

    final watermarkRect = Rect.fromLTWH(
      originalImage.width  - logoSize - rightMargin,
      originalImage.height - logoSize - bottomMargin,
      logoSize,
      logoSize,
    );

    paintImage(
      canvas: canvas,
      rect: watermarkRect,
      image: watermarkImage,
      fit: BoxFit.fill,
      opacity: 0.6, // keep same opacity as preview if you want; preview uses 1.0
    );
  }
} catch (e) {
  debugPrint("watermark draw error $e");
}


    final mergedImage =
        await recorder
            .endRecording()
            .toImage(
      originalImage.width,
      originalImage.height,
    );

    final byteData =
        await mergedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final bytes =
        byteData!.buffer.asUint8List();

    final folder = await StorageService.getPhotoDirectory();

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final finalPath =
        "${folder.path}/PHOTO_$timestamp.jpg";

    lastImagePath =
        (await File(finalPath)
                .writeAsBytes(bytes))
            .path;

    await saveLatLngToExif(
      imagePath: lastImagePath!,
      latitude: lat ?? 0,
      longitude: lng ?? 0,
    );

  } catch (e) {

    debugPrint("PHOTO SAVE ERROR $e");

  }

  if (mounted) {

    setState(() {

      isProcessing = false;

    });

  }

}


static const MethodChannel exifChannel =
    MethodChannel("exif_channel");

Future<void> saveLatLngToExif({

  required String imagePath,

  required double latitude,

  required double longitude,

}) async {

  try {

    await exifChannel.invokeMethod(

      "writeExif",

      {

        "path": imagePath,

        "lat": latitude,

        "lng": longitude,

      },

    );

    debugPrint("EXIF WRITTEN");

  } catch (e) {

    debugPrint("EXIF ERROR $e");

  }

}

  void openPreview() {
    final path = currentMode == CameraMode.video ? lastVideoPath : lastImagePath;
    final isVideo = currentMode == CameraMode.video;
    
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capture ${isVideo ? 'video' : 'photo'} first")),
      );
      return;
    }
    
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => MediaViewer(
          mediaPath: path, 
          isVideo: isVideo,
          address: address,
          lat: lat ?? 0,
          lng: lng ?? 0,
          dateTime: dateTime,
          timezone: timezone,
        ),
      ),
    );
  }

  Future setZoom(double z) async {
    zoom = z;
    await controller?.setZoomLevel(z);
    setState(() {});
  }

  Future toggleFlash() async {
    flashMode = flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await controller?.setFlashMode(flashMode);
    setState(() {});
  }

  @override
  void dispose() {
    _clockTimer?.cancel(); // ADD
    _durationTimer?.cancel();
    _locationUpdateTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    if (loadingCamera) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (!hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text("Camera permission denied", style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => openAppSettings(), 
                child: const Text("Open App Settings"),
              ),
            ],
          ),
        ),
      );
    }

    if (cameraError != null) {
       return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Camera Error: $cameraError", style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final overlayScale = isLargeScreen ? 1.3 : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!isProcessing)

  Positioned.fill(

    child: LayoutBuilder(

      builder: (context, constraints) {

        double logoSize =
            constraints.maxWidth * 0.09;

        if (logoSize < 35) logoSize = 35;
        if (logoSize > 60) logoSize = 60;

        // Scale logo for larger screens
        if (isLargeScreen) {
          logoSize = constraints.maxWidth * 0.05;
          if (logoSize < 50) logoSize = 50;
          if (logoSize > 80) logoSize = 80;
        }

        return Stack(

          children: [

            /// CAMERA PREVIEW
            CameraPreview(controller!),



            /// WATERMARK inside camera frame
            if (watermarkPath != null &&
                File(watermarkPath!).existsSync())

              Positioned(

                bottom:  MediaQuery.of(context).size.height * 0.12,
                right: 10,

                child: Opacity(

                  opacity: 1,

                  child: Image.file(

                    File(watermarkPath!),

                    width: logoSize,
                    height: logoSize,

                    fit: BoxFit.cover,

                  ),

                ),

              ),

          ],

        );

      },

    ),

  ),

          Positioned(
  top: isLargeScreen ? 80 : 60,
  left: isLargeScreen ? 30 : 20,
  child: Row(
    children: [

      /// FLASH BUTTON
      GestureDetector(
        onTap: toggleFlash,
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 14 : 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(isLargeScreen ? 40 : 30),
          ),
          child: Icon(
            flashMode == FlashMode.off
                ? Icons.flash_off
                : Icons.flash_on,
            color: Colors.white,
            size: isLargeScreen ? 28 : 24,
          ),
        ),
      ),

      SizedBox(width: isLargeScreen ? 16 : 12),

      /// CAMERA SWITCH
      GestureDetector(
        onTap: switchCamera,
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 14 : 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(isLargeScreen ? 40 : 30),
          ),
          child: Icon(
            Icons.cameraswitch,
            color: Colors.white,
            size: isLargeScreen ? 28 : 24,
          ),
        ),
      ),

    ],
  ),
),



          if (isRecording) ...[
            Positioned(top: 0, left: 0, right: 0, child: Divider(color: Colors.red, thickness: isLargeScreen ? 6 : 4)),
            Positioned(
              top: isLargeScreen ? 80 : 60, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24 : 16,
                    vertical: isLargeScreen ? 12 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(isLargeScreen ? 30 : 20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: isLargeScreen ? 16 : 12,
                      height: isLargeScreen ? 16 : 12,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                    SizedBox(width: isLargeScreen ? 12 : 8),
                    Text(
                      _formatDuration(recordingDuration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 24 : 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],

          if (isProcessing && currentMode == CameraMode.photo)
            RepaintBoundary(
              key: _boundaryKey,
              child: Stack(fit: StackFit.expand, children: [
                Image.file(File(lastImagePath!), fit: BoxFit.cover),
                Positioned(
                  bottom: isLargeScreen ? 80 : 50,
                  left: isLargeScreen ? 30 : 16,
                  right: isLargeScreen ? 30 : 16,
                  child: LocationOverlayCard(address: address, lat: lat ?? 0, lng: lng ?? 0, dateTime: dateTime, timezone: timezone),
                ),
              ]),
            ),

          if (isProcessing) Container(color: Colors.black26, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            SizedBox(height: isLargeScreen ? 16 : 10),
            Text(
              currentMode == CameraMode.photo ? "Loading Map Tiles..." : "Saving Video...",
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeScreen ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]))),

          if (!isProcessing) ...[
            if (currentMode == CameraMode.photo) ...[
              CameraOverlayUI(
                onCapture: capturePhoto,
                onPreviewTap: openPreview,
                lastImagePath: lastImagePath,
                onFlashToggle: toggleFlash,
                flashMode: flashMode,
                zoom: zoom,
                onZoomChanged: setZoom,
                onVideoTap: () => switchMode(CameraMode.video),
              ),
              // Positioned(
              //   top: isLargeScreen ? 100 : 70,
              //   right: isLargeScreen ? 30 : 20,
              //   child: const CompassWidget(),
              // ),

              if (!loadingLocation) Positioned(
                bottom: isLargeScreen ? 200 : 150,
                left: isLargeScreen ? 30 : 20,
                right: isLargeScreen ? 30 : 20,
                child: LocationOverlayCard(address: address, lat: lat ?? 0, lng: lng ?? 0, dateTime: dateTime, timezone: timezone),
              ),
            ],
            if (currentMode == CameraMode.video) ...[
              VideoOverlayUI(
                isRecording: isRecording,
                recordingDuration: recordingDuration,
                onToggleRecording: toggleRecording,
                onPreviewTap: openPreview,
                lastVideoPath: lastVideoPath,
                onPhotoTap: () => switchMode(CameraMode.photo),
                onFlashToggle: toggleFlash,
                flashMode: flashMode,
                zoom: zoom,
                onZoomChanged: setZoom,
              ),
              // Positioned(
              //   top: isLargeScreen ? 100 : 70,
              //   right: isLargeScreen ? 30 : 20,
              //   child: const CompassWidget(),
              // ),

              if (!loadingLocation) Positioned(
                bottom: isLargeScreen ? (isRecording ? 230 : 200) : (isRecording ? 170 : 150),
                left: isLargeScreen ? 30 : 16,
                right: isLargeScreen ? 30 : 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isRecording ? 1.0 : 0.8,
                  child: LocationOverlayCard(address: address, lat: lat ?? 0, lng: lng ?? 0, dateTime: dateTime, timezone: timezone, isRecording: isRecording),
                ),
              ),

            ],
          ],

          // ── Video processing progress overlay ─────────────────────────────
          // Shown while FFmpeg burns the geotag overlay onto the video.
          // Fades in/out automatically via AnimatedSwitcher.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isBurningOverlay
                ? _VideoProcessingOverlay(progress: _videoProgress)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Video Processing Progress Overlay ─────────────────────────────────────────
/// Full-screen frosted-glass overlay shown while FFmpeg burns the geotag overlay.
/// [progress] ranges 0.0 → 1.0 and drives both the arc and the percentage text.
class _VideoProcessingOverlay extends StatefulWidget {
  final double progress;
  const _VideoProcessingOverlay({required this.progress});

  @override
  State<_VideoProcessingOverlay> createState() => _VideoProcessingOverlayState();
}

class _VideoProcessingOverlayState extends State<_VideoProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.progress * 100).toInt().clamp(0, 100);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Circular progress ring ──────────────────────────────────
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 6,
                        color: Colors.white12,
                      ),
                    ),
                    // Progress arc
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: widget.progress),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: val,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(
                            Color.lerp(
                              const Color(0xFF00C6FF),
                              const Color(0xFF00FF88),
                              val,
                            )!,
                          ),
                        ),
                      ),
                    ),
                    // Centre icon with pulse
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF1A2A3A), Color(0xFF0D1A27)],
                          ),
                          border: Border.all(
                            color: Colors.white10,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_file_rounded,
                              color: Color(0xFF00C6FF),
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Label ───────────────────────────────────────────────────
              const Text(
                'Adding Geotag Overlay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pct < 5
                    ? 'Initialising FFmpeg…'
                    : pct < 95
                        ? 'Processing video frames…'
                        : 'Finalising…',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 24),

              // ── Thin animated progress bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (_, val, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                        Color.lerp(
                          const Color(0xFF00C6FF),
                          const Color(0xFF00FF88),
                          val,
                        )!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MediaViewer extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String? address;
  final double? lat;
  final double? lng;
  final String? dateTime;
  final String? timezone;

  const MediaViewer({super.key, required this.mediaPath, required this.isVideo, this.address, this.lat, this.lng, this.dateTime, this.timezone});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) { if (mounted) { setState(() => _isVideoInitialized = true); _controller.play(); } })
        ..setLooping(true);
    }
  }

  @override
  void dispose() {
    if (widget.isVideo) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final iconSize = isLargeScreen ? 32.0 : 24.0;
    final overlaySize = isLargeScreen ? 100.0 : 80.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: widget.isVideo
                ? (_isVideoInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: GestureDetector(
                          onTap: () => setState(() =>
                              _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white))
                : Image.file(File(widget.mediaPath), fit: BoxFit.contain),
          ),
          if (_isVideoInitialized && !_controller.value.isPlaying)
            Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white54,
                size: overlaySize,
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          if (widget.isVideo && widget.address != null)
            Positioned(
              bottom: isLargeScreen ? 30 : 16,
              left: isLargeScreen ? 30 : 16,
              right: isLargeScreen ? 30 : 16,
              child: GestureDetector(
                onTap: () => setState(() => _showOverlay = !_showOverlay),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _showOverlay ? Offset.zero : const Offset(0, 1.5),
                  child: LocationOverlayCard(
                    address: widget.address!,
                    lat: widget.lat ?? 0,
                    lng: widget.lng ?? 0,
                    dateTime: widget.dateTime ?? "",
                    timezone: widget.timezone ?? "",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}