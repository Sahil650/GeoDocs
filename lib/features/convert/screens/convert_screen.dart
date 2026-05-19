import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:open_file/open_file.dart';

import '../models/geotag_data.dart';
import '../../../data/services/storage_service.dart';

import '../../export/services/pdf_export_service.dart';
import '../../export/services/word_export_service.dart';

import '../../export/screens/gpx_kml_screen.dart';

import '../../compress/screens/image_compress_screen.dart';
import '../../compress/screens/file_compress_screen.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {

  List<File> selectedFiles = [];
  List<GeoTagData> geoDataList = [];

  String format = "jpg";
  int quality = 90;
  bool loading = false;

  final formats = ["jpg", "png"];

  ButtonStyle softButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: Colors.grey.shade100,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Future<void> pickImages() async {

    final picker = ImagePicker();

    final picked = await picker.pickMultiImage();

    if (picked.isEmpty) return;

    setState(() {

      for (var file in picked) {

        selectedFiles.add(File(file.path));

        geoDataList.add(
          GeoTagData(
            fileName: file.name,
            latitude: 0,
            longitude: 0,
            datetime: DateTime.now().toString(),
            address: "",
            timezone: "",
            employeeName: "",
          ),
        );

      }

    });

  }

  void removeImage(int index) {

    setState(() {

      selectedFiles.removeAt(index);

      geoDataList.removeAt(index);

    });

  }

  void clearAll() {

    setState(() {

      selectedFiles.clear();

      geoDataList.clear();

    });

  }

  Future<void> convertImages() async {

    if (selectedFiles.isEmpty) return;

    setState(() => loading = true);

    final dir = await StorageService.getConvertedDirectory();

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (int i = 0; i < selectedFiles.length; i++) {

      final bytes = await selectedFiles[i].readAsBytes();

      final result = await compute(
        processImage,
        {
          "bytes": bytes,
          "format": format,
          "quality": quality,
        },
      );

      final path =
          "${dir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}_$i.$format";

      await File(path).writeAsBytes(result);

    }

    setState(() => loading = false);

    showMsg("Images saved in Converted tab");

  }

  static List<int> processImage(Map<String, dynamic> map) {

    final bytes = map["bytes"];
    final String format = map["format"];
    final int quality = map["quality"];

    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Invalid image");
    }

    if (format == "png") {

      return img.encodePng(
        image,
        level: (100 - quality) ~/ 10,
      );

    } else {

      return img.encodeJpg(
        image,
        quality: quality,
      );

    }

  }

  Future<void> exportPDF() async {

    if (geoDataList.isEmpty) {
      showMsg("Select images");
      return;
    }

    final file = await exportPdf(geoDataList);

    showMsg("PDF saved");

    await OpenFile.open(file.path);

  }

  Future<void> exportWordFile() async {

    if (geoDataList.isEmpty) {
      showMsg("Select images");
      return;
    }

    final pdfFile = await exportPdf(geoDataList);

    final folder = pdfFile.parent.path;

    final wordFile =
        await exportWord(geoDataList, customPath: folder);

    showMsg("Word saved");

    await OpenFile.open(wordFile.path);

  }

  void showMsg(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("Convert + Export GeoTag"),

        actions: [

          if (selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: clearAll,
            ),

        ],

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                Text(
                  "Images (${selectedFiles.length})",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),

                ElevatedButton.icon(
                  onPressed: pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text("Add Images"),
                ),

              ],

            ),

            const SizedBox(height: 12),

            if (selectedFiles.isEmpty)

              Container(

                height: 180,
                alignment: Alignment.center,

                decoration: BoxDecoration(

                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),

                ),

                child: const Text("No Images Selected"),

              )

            else

              SizedBox(

                height: 200,

                child: GridView.builder(

                  scrollDirection: Axis.horizontal,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount: 1,
                    mainAxisSpacing: 8,

                  ),

                  itemCount: selectedFiles.length,

                  itemBuilder: (context, index) {

                    return Stack(

                      children: [

                        ClipRRect(

                          borderRadius: BorderRadius.circular(8),

                          child: Image.file(
                            selectedFiles[index],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),

                        ),

                        Positioned(

                          top: 4,
                          right: 4,

                          child: GestureDetector(

                            onTap: () => removeImage(index),

                            child: const CircleAvatar(

                              radius: 12,
                              backgroundColor: Colors.red,

                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),

                            ),

                          ),

                        ),

                      ],

                    );

                  },

                ),

              ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(

              initialValue: format,

              decoration: const InputDecoration(
                labelText: "Output Format",
                border: OutlineInputBorder(),
              ),

              items: formats
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toUpperCase()),
                      ))
                  .toList(),

              onChanged: (v) {
                if (v != null) {
                  setState(() => format = v);
                }
              },

            ),

            const SizedBox(height: 12),

            Text("Quality: $quality"),

            Slider(

              value: quality.toDouble(),
              min: 20,
              max: 100,
              divisions: 8,
              label: "$quality",

              onChanged: (v) {
                setState(() => quality = v.round());
              },

            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(

              style: softButtonStyle(),

              onPressed: loading ? null : convertImages,

              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_fix_high),

              label: Text(
                loading ? "Processing..." : "Convert Images",
              ),

            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              "Export GeoTag Data",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(

              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    style: softButtonStyle(),
                    onPressed: exportPDF,
                    icon:
                        const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text("PDF"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    style: softButtonStyle(),
                    onPressed: exportWordFile,
                    icon:
                        const Icon(Icons.description_outlined),
                    label: const Text("Word"),
                  ),
                ),

              ],

            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              "Export Route",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(

              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    style: softButtonStyle(),
                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const GpxKmlScreen(type: "gpx"),
                        ),
                      );

                    },
                    icon: const Icon(Icons.alt_route),
                    label: const Text("GPX"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    style: softButtonStyle(),
                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const GpxKmlScreen(type: "kml"),
                        ),
                      );

                    },
                    icon: const Icon(Icons.public),
                    label: const Text("KML"),
                  ),
                ),

              ],

            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              "Compression",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(

              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    style: softButtonStyle(),
                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ImageCompressScreen(),
                        ),
                      );

                    },
                    icon: const Icon(Icons.photo_size_select_small),
                    label: const Text("Compress Images"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    style: softButtonStyle(),
                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                               const FileCompressScreen(),
                        ),
                      );

                    },
                    icon: const Icon(Icons.archive),
                    label: const Text("Compress Files"),
                  ),
                ),

              ],

            ),

            const SizedBox(height: 40),

          ],

        ),

      ),

    );

  }

}