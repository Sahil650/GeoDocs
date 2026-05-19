import 'dart:io';
import 'package:image/image.dart' as img;

class ImageProcessingService {

  static Future<File> enhanceDocument(String path) async {

    final bytes = await File(path).readAsBytes();

    img.Image? image = img.decodeImage(bytes);

    if(image == null) {
      return File(path);
    }

    /// convert to grayscale (scan effect)
    image = img.grayscale(image);

    /// increase contrast
    image = img.adjustColor(

      image,

      contrast: 1.2,

      brightness: 1.05,
    );

    final newPath =
        path.replaceAll(".jpg", "_scan.jpg");

    await File(newPath).writeAsBytes(

      img.encodeJpg(image, quality: 95),
    );

    return File(newPath);
  }
}