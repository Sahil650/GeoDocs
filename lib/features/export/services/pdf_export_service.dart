import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

import '../../convert/models/geotag_data.dart';
import '../../../data/services/storage_service.dart';

Future<File> exportPdf(List<GeoTagData> dataList) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "GeoTag Report",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Total Images: ${dataList.length}",
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 16),

            // ── Table with all records ──
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: [
                "#",
                "File",
                "Address",
                "Lat",
                "Lng",
                "DateTime",
                "TZ",
                "Employee",
              ],
              data: List.generate(
                dataList.length,
                (i) => [
                  "${i + 1}",
                  dataList[i].fileName,
                  dataList[i].address,
                  dataList[i].latitude.toString(),
                  dataList[i].longitude.toString(),
                  dataList[i].datetime,
                  dataList[i].timezone,
                  dataList[i].employeeName,
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // If there are many records, also add detail pages per image
  for (int i = 0; i < dataList.length; i++) {
    final d = dataList[i];
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "GeoTag Detail — Image ${i + 1}",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildRow("File Name", d.fileName),
                _buildRow("Address", d.address),
                _buildRow(
                    "Latitude", d.latitude.toString()),
                _buildRow("Longitude",
                    d.longitude.toString()),
                _buildRow("Date / Time", d.datetime),
                _buildRow("Timezone", d.timezone),
                _buildRow("Employee", d.employeeName),
              ],
            ),
          );
        },
      ),
    );
  }

  final dir = await StorageService.getExportDirectory();
  final file = File("${dir.path}/geotag_report.pdf");
  await file.writeAsBytes(await pdf.save());
  return file;
}

pw.Widget _buildRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [ 
          pw.TextSpan(
            text: "$label : ",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
