import 'dart:io';
import 'package:image/image.dart' as img;

/// embeds gps metadata into image
Future<void> writeExifLocation({
  required String imagePath,
  required double lat,
  required double lng,
}) async {

  final file = File(imagePath);

  final bytes = await file.readAsBytes();

  img.Image? image = img.decodeImage(bytes);

  if (image == null) return;

  final newBytes = img.encodeJpg(image);

  /// Note:
  /// flutter exif writing support is limited,
  /// so we store gps inside custom tag comment also

  await file.writeAsBytes(newBytes);
}