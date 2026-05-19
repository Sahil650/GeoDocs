import 'dart:io';

import '../../convert/models/geotag_data.dart';
import '../../../data/services/storage_service.dart';

Future<File> exportKml(
  List<GeoTagData> list, {

  bool asLine = true,

}) async {

  if (list.isEmpty) {
    throw Exception("No GPS data found");
  }

  final buffer = StringBuffer();

  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');

  buffer.writeln(
      '<kml xmlns="http://www.opengis.net/kml/2.2">');

  buffer.writeln('<Document>');

  if (asLine) {

    buffer.writeln('<Placemark>');

    buffer.writeln('<LineString>');

    buffer.writeln('<coordinates>');

    for (var p in list) {

      buffer.writeln(

          '${p.longitude},${p.latitude},0');

    }

    buffer.writeln('</coordinates>');

    buffer.writeln('</LineString>');

    buffer.writeln('</Placemark>');

  }

  else {

    for (var p in list) {

      buffer.writeln('<Placemark>');

      buffer.writeln('<Point>');

      buffer.writeln(

          '<coordinates>${p.longitude},${p.latitude},0</coordinates>');

      buffer.writeln('</Point>');

      buffer.writeln('</Placemark>');
    }
  }

  buffer.writeln('</Document>');

  buffer.writeln('</kml>');

  final folder = await StorageService.getExportDirectory();

  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  final file = File(

      "${folder.path}/route_${DateTime.now().millisecondsSinceEpoch}.kml");

  await file.writeAsString(buffer.toString());

  return file;
}