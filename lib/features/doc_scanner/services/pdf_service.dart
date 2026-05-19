import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';

class PdfService {

  static Future<String> createPdf(

      List<String> images) async {

    final pdf = pw.Document();

    for(String imgPath in images){

      final imgFile =
          File(imgPath).readAsBytesSync();

      final image =
          pw.MemoryImage(imgFile);

      pdf.addPage(

        pw.Page(

          build: (pw.Context context){

            return pw.Center(

              child: pw.Image(image),
            );
          },
        ),
      );
    }

    final dir =
        Directory(

      "/storage/emulated/0/Documents/GeoScanner",
    );

    if(!dir.existsSync()){

      dir.createSync(recursive: true);
    }

    final filePath =

        "${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf";

    final file = File(filePath);

    await file.writeAsBytes(

        await pdf.save());

    return filePath;
  }
}







