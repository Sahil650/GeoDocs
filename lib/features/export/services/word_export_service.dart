// import 'dart:io';

// import 'package:path_provider/path_provider.dart';

// import '../../convert/models/geotag_data.dart';

// Future<File> exportWord(List<GeoTagData> dataList) async {
//   final dir =
//       await getApplicationDocumentsDirectory();
//   final file =
//       File("${dir.path}/geotag_report.doc");

//   final buffer = StringBuffer();

//   buffer.writeln("GEOTAG REPORT");
//   buffer.writeln(
//       "Total Images: ${dataList.length}");
//   buffer.writeln(
//       "========================================\n");

//   for (int i = 0; i < dataList.length; i++) {
//     final d = dataList[i];

//     buffer.writeln("--- Image ${i + 1} ---");
//     buffer.writeln("File:");
//     buffer.writeln(d.fileName);
//     buffer.writeln("Address:");
//     buffer.writeln(d.address);
//     buffer.writeln("Latitude:");
//     buffer.writeln(d.latitude);
//     buffer.writeln("Longitude:");
//     buffer.writeln(d.longitude);
//     buffer.writeln("DateTime:");
//     buffer.writeln(d.datetime);
//     buffer.writeln("Timezone:");
//     buffer.writeln(d.timezone);
//     buffer.writeln("Employee:");
//     buffer.writeln(d.employeeName);
//     buffer.writeln(
//         "----------------------------------------\n");
//   }

//   await file.writeAsString(buffer.toString());
//   return file;
// }



import 'dart:io';

import '../../convert/models/geotag_data.dart';
import '../../../data/services/storage_service.dart';

Future<File> exportWord(
  List<GeoTagData> dataList, {

  String? customPath,

}) async {

  /// same folder where PDF is saved
  Directory? dir;
  
  if (customPath != null) {
    dir = Directory(customPath);
  } else {
    dir = await StorageService.getExportDirectory();
  }

  if (!await dir.exists()) {

    await dir.create(recursive: true);

  }

  final file =
      File("${dir.path}/geotag_report.docx");

  final buffer = StringBuffer();

  buffer.writeln("GEOTAG REPORT");

  buffer.writeln(
      "Total Images: ${dataList.length}");

  buffer.writeln(
      "========================================\n");

  for (int i = 0; i < dataList.length; i++) {

    final d = dataList[i];

    buffer.writeln("--- Image ${i + 1} ---");

    buffer.writeln("File:");
    buffer.writeln(d.fileName);

    buffer.writeln("Address:");
    buffer.writeln(d.address);

    buffer.writeln("Latitude:");
    buffer.writeln(d.latitude);

    buffer.writeln("Longitude:");
    buffer.writeln(d.longitude);

    buffer.writeln("DateTime:");
    buffer.writeln(d.datetime);

    buffer.writeln("Timezone:");
    buffer.writeln(d.timezone);

    buffer.writeln("Employee:");
    buffer.writeln(d.employeeName);

    buffer.writeln(
        "----------------------------------------\n");

  }

  await file.writeAsString(
    buffer.toString(),
  );

  return file;

}