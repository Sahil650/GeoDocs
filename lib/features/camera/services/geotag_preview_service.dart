


import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/map_service.dart';

class GeoTagPreviewService {

  static Future<String> createPreview({
    required String address,
    required double lat,
    required double lng,
    required String dateTime,
    required String timezone,
  }) async {

    // ----- 1. Download the map tile via MapService -----
    ui.Image? mapImage;
    try {
      final mapPath = await MapService.downloadMap(lat, lng);
      final bytes = await File(mapPath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 260, targetHeight: 260);
      final frame = await codec.getNextFrame();
      mapImage = frame.image;
    } catch (_) {
      // If map download fails we still render text-only
    }

    // ----- 2. Canvas dimensions -----
    const double canvasW = 900;
    const double canvasH = 280;
    const double mapSize = 260;
    const double mapLeft = 10;
    const double mapTop = 10;
    const double textLeft = mapLeft + mapSize + 20;
    const double textWidth = canvasW - textLeft - 20;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasW, canvasH),
      Paint()..color = const Color(0xEE000000),
    );

    // ----- 3. Draw map tile (clipped to rounded rect) -----
    if (mapImage != null) {
      const mapRect = Rect.fromLTWH(mapLeft, mapTop, mapSize, mapSize);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(mapRect, const Radius.circular(10)));
      paintImage(
        canvas: canvas,
        rect: mapRect,
        image: mapImage,
        fit: BoxFit.cover,
      );
      canvas.restore();

      // Pin icon overlay — draw a simple red circle + dot
      final pinPaint = Paint()..color = const Color(0xFFFF3B3B);
      const cx = mapLeft + mapSize / 2;
      const cy = mapTop + mapSize / 2;
      canvas.drawCircle(const Offset(cx, cy - 2), 14, pinPaint);
      canvas.drawCircle(
        const Offset(cx, cy - 2),
        6,
        Paint()..color = Colors.white,
      );
      // Pin tail
      final path = Path()
        ..moveTo(cx - 6, cy + 10)
        ..lineTo(cx + 6, cy + 10)
        ..lineTo(cx, cy + 22)
        ..close();
      canvas.drawPath(path, pinPaint);

      // Map border
      canvas.drawRRect(
        RRect.fromRectAndRadius(mapRect, const Radius.circular(10)),
        Paint()
          ..color = const Color(0x44FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // ----- 4. Draw text -----
    void drawLine(Canvas c, String text, double y,
        {double fontSize = 24, Color color = Colors.white, bool mono = false}) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: TextAlign.left),
      )
        ..pushStyle(ui.TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: mono ? 'monospace' : null,
          fontWeight: FontWeight.normal,
        ))
        ..addText(text);
      final para = builder.build()
        ..layout(const ui.ParagraphConstraints(width: textWidth));
      c.drawParagraph(para, Offset(textLeft, y));
    }

    // Address (two lines, smaller)
    final addrBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.left, maxLines: 3, ellipsis: '…'),
    )
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
      ..addText(address);
    final addrPara = addrBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: textWidth));
    canvas.drawParagraph(addrPara, const Offset(textLeft, 18));

    // Lat / Lng
    drawLine(canvas,
      'Lat: ${lat.toStringAsFixed(6)}   Lng: ${lng.toStringAsFixed(6)}',
      108, fontSize: 20, color: const Color(0xFF80C8FF), mono: true);

    // DateTime
    drawLine(canvas, dateTime, 148, fontSize: 19, color: const Color(0xFFCCCCCC), mono: true);

    // Timezone
    drawLine(canvas, timezone, 182, fontSize: 18, color: const Color(0xFF999999));



    // ----- 5. Encode to PNG -----
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/geotag_preview.png");
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file.path;
  }
}