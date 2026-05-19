import 'dart:io';

import '../../convert/models/geotag_data.dart';
import '../../../data/services/storage_service.dart';

Future<File> exportGpx(
  List<GeoTagData> list,
) async {

  if (list.isEmpty) {
    throw Exception("No GPS data found");
  }

  final buffer = StringBuffer();

  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');

  buffer.writeln(
      '<gpx version="1.1" creator="GeoTag Camera" '
      'xmlns="http://www.topografix.com/GPX/1/1">');

  buffer.writeln('<trk>');
  buffer.writeln('<name>GeoTag Route</name>');
  buffer.writeln('<trkseg>');

  for (var p in list) {

    buffer.writeln(
        '<trkpt lat="${p.latitude}" lon="${p.longitude}">');

    buffer.writeln('<time>${p.datetime}</time>');

    buffer.writeln('</trkpt>');
  }

  buffer.writeln('</trkseg>');
  buffer.writeln('</trk>');
  buffer.writeln('</gpx>');

  final folder = await StorageService.getExportDirectory();

  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  final file = File(

      "${folder.path}/route_${DateTime.now().millisecondsSinceEpoch}.gpx");

  await file.writeAsString(buffer.toString());

  return file;
}