import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class MediaScannerService {
  static const _channel = MethodChannel('com.gps_map_camera_app/media_scan');

  /// Notifies Android MediaStore about a newly saved file at [filePath].
  ///
  /// After this call the file will appear in gallery apps (Google Photos,
  /// Files, etc.) immediately — without waiting for the next system scan.
  ///
  /// Returns the MediaStore URI string on success, or null if scanning failed.
  static Future<String?> scanFile(String filePath) async {
    try {
      final uri = await _channel.invokeMethod<String>(
        'scanFile',
        {'path': filePath},
      );
      debugPrint('MediaScanner: indexed $filePath → $uri');
      return uri;
    } catch (e) {
      debugPrint('MediaScanner error: $e');
      return null;
    }
  }
}
