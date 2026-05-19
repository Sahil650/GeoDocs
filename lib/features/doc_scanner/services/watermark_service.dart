import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class WatermarkService {
  static Future<File> addGeoWatermark({
    required String imagePath,
    required String address,
    required double lat,
    required double lng,
  }) async {
    final bytes = await File(imagePath).readAsBytes();

    img.Image image = img.decodeImage(bytes)!;

    /// date time
    final now = DateTime.now();

    final formattedDate = DateFormat("dd MMM yyyy   hh:mm a").format(now);

    /// wrap long address
    List<String> addressLines = _wrapText(address, 35);

    List<String> lines = [
      ...addressLines,
      "Lat: ${lat.toStringAsFixed(6)}",
      "Lng: ${lng.toStringAsFixed(6)}",
      formattedDate,
      // "Geo Fusion",
    ];

    /// position bottom-left
    int startX = 20;

    int startY = image.height - (lines.length * 26) - 20;

    /// transparent background strip
    int padding = 20;

    int bgHeight = (lines.length * 30) + padding;

    img.fillRect(
      image,
      x1: 0,
      y1: image.height - bgHeight,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgba8(0, 0, 0, 80),
    );

    /// draw text only (transparent background)
    for (int i = 0; i < lines.length; i++) {
      img.drawString(
        image,
        lines[i],
        font: img.arial24,
        x: startX,
        y: startY + (i * 26),
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    final newPath = imagePath.replaceAll(".jpg", "_wm.jpg");

    await File(newPath).writeAsBytes(
      img.encodeJpg(image),
    );

    return File(newPath);
  }

  /// auto wrap long address
  static List<String> _wrapText(
    String text,
    int maxLength,
  ) {
    List<String> words = text.split(" ");

    List<String> lines = [];

    String line = "";

    for (String word in words) {
      if ((line + word).length > maxLength) {
        lines.add(line);

        line = "$word ";
      } else {
        line += "$word ";
      }
    }

    lines.add(line);

    return lines;
  }
}
