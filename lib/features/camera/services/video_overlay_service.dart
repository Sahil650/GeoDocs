import 'package:flutter/services.dart';

class VideoOverlayService {
  static const _channel = MethodChannel('video_overlay_channel');

  /// EventChannel that streams processing progress as a [double] from 0.0 to 1.0.
  /// Subscribe before calling [burnOverlay] and cancel after it completes.
  static const _progressChannel =
      EventChannel('com.gps_map_camera_app/video_progress');

  static Stream<double> get progressStream =>
      _progressChannel
          .receiveBroadcastStream()
          .map((e) => (e as num).toDouble().clamp(0.0, 1.0));

  /// Burns [overlayPngPath] onto every frame of [inputVideoPath] using FFmpeg
  /// and writes the result to [outputVideoPath].
  ///
  /// Embed GPS into MP4 location metadata box so apps like Google Photos can
  /// read the location without needing to open the file.
  ///
  /// Monitor [progressStream] for 0.0 → 1.0 progress updates while this runs.
  /// Returns [outputVideoPath] on success; throws [PlatformException] on failure.
  static Future<String> burnOverlay({
    required String inputVideoPath,
    required String overlayPngPath,
    required String outputVideoPath,
    double lat = 0.0,
    double lng = 0.0,
  }) async {
    final result = await _channel.invokeMethod<String>('burnOverlay', {
      'inputPath':   inputVideoPath,
      'overlayPath': overlayPngPath,
      'outputPath':  outputVideoPath,
      'lat':         lat,
      'lng':         lng,
    });
    return result!;
  }
}