import 'dart:io';
import 'package:image/image.dart' as img;

class ScanProcessor {

  static Future<File> applyFilter({

    required File file,
    required String filter,

  }) async {

    final bytes = await file.readAsBytes();

    img.Image? image = img.decodeImage(bytes);

    if(image == null) return file;

    switch(filter){

      case "bw":

        image = img.grayscale(image);

        image = img.adjustColor(

          image,

          contrast: 1.6,
          brightness: 1.05,
        );

        break;

      case "gray":

        image = img.grayscale(image);

        break;

      case "enhance":

        image = img.adjustColor(

          image,

          contrast: 1.2,
          saturation: 1.1,
          brightness: 1.05,
        );

        break;

      case "sharp":

        image = img.convolution(

          image,

          filter: [

            0,-1,0,
            -1,5,-1,
            0,-1,0

          ],
        );

        break;

      case "none":

        break;
    }

    final newFile = File(file.path);

    await newFile.writeAsBytes(

      img.encodeJpg(image, quality: 95),
    );

    return newFile;
  }
}