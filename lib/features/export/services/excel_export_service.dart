import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../convert/models/geotag_data.dart';

Future<File> exportExcel(

    List<GeoTagData> list) async {

  final excel = Excel.createExcel();

  final sheet = excel['GeoTag'];

  /// header

  sheet.appendRow([

    TextCellValue("File"),

    TextCellValue("Address"),

    TextCellValue("Latitude"),

    TextCellValue("Longitude"),

    TextCellValue("DateTime"),

    TextCellValue("Timezone"),

    TextCellValue("Employee"),

  ]);



  /// data

  for (var e in list){

    sheet.appendRow([

      TextCellValue(e.fileName),

      TextCellValue(e.address),

      TextCellValue(e.latitude.toString()),

      TextCellValue(e.longitude.toString()),

      TextCellValue(e.datetime),

      TextCellValue(e.timezone),

      TextCellValue(e.employeeName),

    ]);

  }


  final dir =
      await getApplicationDocumentsDirectory();

  final file =
      File("${dir.path}/geotag.xlsx");

  await file.writeAsBytes(
      excel.encode()!);

  return file;

}