import 'package:flutter/services.dart';

class NativeScanner {

  static const platform = MethodChannel('document_scanner');

  static Future<String?> scanDocument({
    required String imagePath,
    required List<Offset> points,
  }) async {

    try {

      List<List<double>> pts = points.map((p) => [p.dx, p.dy]).toList();

      final String? result = await platform.invokeMethod(
        'scanDocument',
        {
          "path": imagePath,
          "points": pts,
        },
      );

      return result;

    } catch (e) {
      return null;
    }
  }
}