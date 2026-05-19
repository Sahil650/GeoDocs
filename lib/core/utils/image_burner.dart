import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageBurner {

  static Future<File> burnDataToImage({

    required File originalImage,
    required String address,
    required String lat,
    required String lng,
    required String dateTime,
    ui.Image? mapSnapshot,

  }) async {

    final bytes =
        await originalImage.readAsBytes();

    img.Image photo =
        img.decodeImage(bytes)!;

    int imgW = photo.width;
    int imgH = photo.height;

    /// professional card size
    int cardW = (imgW * 0.90).toInt();
    int cardH = (cardW * 0.22).toInt();

    img.Image card =
        img.Image(
          width: cardW,
          height: cardH,
        );

    /// dark transparent background
    img.fill(

      card,

      color:
      img.ColorRgba8(
          20, 20, 20, 200),

    );

    /// map square size
    int mapSize =
        (cardH * 0.65).toInt();

    int mapX = 18;

    int mapY =
        (cardH - mapSize) ~/ 2;

    /// draw minimap snapshot
    if (mapSnapshot != null) {

      final byteData =
      await mapSnapshot.toByteData(
        format:
        ui.ImageByteFormat.png,
      );

      Uint8List png =
      byteData!.buffer.asUint8List();

      img.Image? map =
      img.decodeImage(png);

      if (map != null) {

        img.Image resized =
        img.copyResize(

          map,

          width: mapSize,
          height: mapSize,

        );

        img.compositeImage(

          card,
          resized,

          dstX: mapX,
          dstY: mapY,

        );

      }

    }

    /// text position
    int textX =
        mapX + mapSize + 22;

    int y = 18;

    /// multiline address
    List<String> lines =
        _splitAddress(address);

    for (String line in lines) {

      img.drawString(

        card,
        line,

        font: img.arial24,

        x: textX,
        y: y,

        color:
        img.ColorRgb8(
            255,255,255),

      );

      y += 26;

    }

    y += 6;

    img.drawString(

      card,
      "Lat: $lat",

      font: img.arial14,

      x: textX,
      y: y,

      color:
      img.ColorRgb8(
          220,220,220),

    );

    y += 18;

    img.drawString(

      card,
      "Lng: $lng",

      font: img.arial14,

      x: textX,
      y: y,

      color:
      img.ColorRgb8(
          220,220,220),

    );

    y += 20;

    img.drawString(

      card,
      dateTime,

      font: img.arial14,

      x: textX,
      y: y,

      color:
      img.ColorRgb8(
          200,200,200),

    );

    /// place card on image
    img.compositeImage(

      photo,
      card,

      dstX:
      (imgW - cardW) ~/ 2,

      dstY:
      imgH - cardH - 60,

    );

    final result =
        img.encodePng(photo);

    final output =
    File(
        "${originalImage.path}_geo.png"
    );

    await output.writeAsBytes(result);

    return output;

  }

  /// split address into multiple lines
  static List<String> _splitAddress(
      String address
      ){

    List<String> parts =
    address.split(",");

    if(parts.length >= 2){

      return [

        "${parts[0]},",

        parts
            .sublist(1)
            .join(",")

      ];

    }

    return [address];

  }

}