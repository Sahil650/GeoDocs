import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageCropperService {

  static Future<File> crop({

    required File file,
    required List<Offset> points,
    required Size screenSize,

  }) async {

    final bytes = await file.readAsBytes();

    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    /// IMAGE aspect ratio
    double imgRatio =
        image.width / image.height;

    double screenRatio =
        screenSize.width / screenSize.height;

    double displayW;
    double displayH;

    /// find displayed size of image
    if (imgRatio > screenRatio) {

      displayW = screenSize.width;

      displayH =
          screenSize.width / imgRatio;

    } else {

      displayH = screenSize.height;

      displayW =
          screenSize.height * imgRatio;

    }

    /// margins because of BoxFit.contain
    double marginX =
        (screenSize.width - displayW) / 2;

    double marginY =
        (screenSize.height - displayH) / 2;

    /// scale from UI → image pixels
    double scaleX =
        image.width / displayW;

    double scaleY =
        image.height / displayH;

    /// convert crop points precisely
    List<Offset> imgPts =
        points.map((p) {

      return Offset(

        (p.dx - marginX) * scaleX,

        (p.dy - marginY) * scaleY,

      );

    }).toList();

    /// sort points properly
    Offset tl = imgPts[0];
    Offset tr = imgPts[1];
    Offset bl = imgPts[2];
    Offset br = imgPts[3];

    /// calculate output size
    int width = max(
      (tr - tl).distance.toInt(),
      (br - bl).distance.toInt(),
    );

    int height = max(
      (bl - tl).distance.toInt(),
      (br - tr).distance.toInt(),
    );

    img.Image output =
        img.Image(width: width, height: height);

    /// perspective mapping
    for (int y = 0; y < height; y++) {

      double v = y / height;

      Offset start =
          Offset.lerp(tl, bl, v)!;

      Offset end =
          Offset.lerp(tr, br, v)!;

      for (int x = 0; x < width; x++) {

        double u = x / width;

        Offset src =
            Offset.lerp(start, end, u)!;

        int px =
            src.dx.clamp(
              0,
              image.width - 1,
            ).toInt();

        int py =
            src.dy.clamp(
              0,
              image.height - 1,
            ).toInt();

        output.setPixel(
          x,
          y,
          image.getPixel(px, py),
        );

      }

    }

    String newPath =
        "${file.path}_accurate.jpg";

    File newFile = File(newPath);

    await newFile.writeAsBytes(

        img.encodeJpg(output, quality: 100));

    return newFile;

  }

}