import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import '../../../data/services/storage_service.dart';
import '../../camera/services/media_scanner_service.dart';

class FileCompressScreen extends StatefulWidget {
  const FileCompressScreen({super.key});

  @override
  State<FileCompressScreen> createState() =>
      _FileCompressScreenState();
}

class _FileCompressScreenState extends State<FileCompressScreen> {

  List<File> selectedFiles = [];

  bool loading = false;

  ButtonStyle softButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Future<void> pickFiles() async {

    final result =
        await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result == null) return;

    selectedFiles = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();

    setState(() {});
  }

  void removeFile(int index) {

    setState(() {

      selectedFiles.removeAt(index);

    });

  }

  Future<void> compressFiles() async {

    if (selectedFiles.isEmpty) {

      showMsg("Select files");

      return;
    }

    setState(() => loading = true);

    try {

      /// resolve Download folder dynamically
      final downloadDir = await StorageService.getExportDirectory();

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final zipPath =
          "${downloadDir.path}/FILES_${DateTime.now().millisecondsSinceEpoch}.zip";

      final encoder =
          ZipFileEncoder();

      encoder.create(zipPath);

      for (final file in selectedFiles) {

        if (file.existsSync()) {

          encoder.addFile(file);

        }

      }

      encoder.close();

      // Scan for media/file indexer
      await MediaScannerService.scanFile(zipPath);

      showMsg("ZIP created");

      print("ZIP PATH: $zipPath");

    } catch (e) {

      showMsg("Compression failed");

      print(e);
    }

    setState(() => loading = false);
  }

  Widget preview(File file) {

    final path =
        file.path.toLowerCase();

    if (path.endsWith(".jpg") ||
        path.endsWith(".png")) {

      return Image.file(
        file,
        fit: BoxFit.cover,
      );
    }

    if (path.endsWith(".pdf")) {

      return const Icon(
        Icons.picture_as_pdf,
        color: Colors.red,
        size: 40,
      );
    }

    if (path.endsWith(".doc") ||
        path.endsWith(".docx")) {

      return const Icon(
        Icons.description,
        size: 40,
      );
    }

    if (path.endsWith(".xlsx")) {

      return const Icon(
        Icons.table_chart,
        size: 40,
      );
    }

    return const Icon(
        Icons.insert_drive_file,
        size: 40);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text("Compress Files"),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                Text(

                  "Files (${selectedFiles.length})",

                  style:
                      const TextStyle(

                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                ElevatedButton.icon(

                  style: softButtonStyle(),

                  onPressed: pickFiles,

                  icon:
                      const Icon(Icons.add),

                  label:
                      const Text("Add Files"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(

              height: 200,

              decoration: BoxDecoration(

                color: Colors.grey.shade300,

                borderRadius:
                    BorderRadius.circular(12),

              ),

              child: selectedFiles.isEmpty

                  ? const Center(

                      child:
                          Text("No Files Selected"),
                    )

                  : ListView.builder(

                      scrollDirection:
                          Axis.horizontal,

                      itemCount:
                          selectedFiles.length,

                      itemBuilder:
                          (_, i) {

                        final file =
                            selectedFiles[i];

                        return Padding(

                          padding:
                              const EdgeInsets.all(
                                  8),

                          child: Stack(

                            children: [

                              Container(

                                width: 120,

                                decoration:

                                    BoxDecoration(

                                  color:
                                      Colors.white,

                                  borderRadius:

                                      BorderRadius.circular(
                                          10),

                                ),

                                child: Column(

                                  children: [

                                    Expanded(

                                      child:
                                          preview(
                                              file),

                                    ),

                                    Padding(

                                      padding:
                                          const EdgeInsets.all(
                                              4),

                                      child: Text(

                                        file.path
                                            .split("/")
                                            .last,

                                        maxLines: 1,

                                        overflow:

                                            TextOverflow
                                                .ellipsis,

                                      ),

                                    ),
                                  ],
                                ),
                              ),

                              Positioned(

                                top: 2,

                                right: 2,

                                child:

                                    GestureDetector(

                                  onTap: () =>
                                      removeFile(
                                          i),

                                  child:

                                      const CircleAvatar(

                                    radius: 10,

                                    backgroundColor:
                                        Colors.red,

                                    child: Icon(

                                      Icons.close,

                                      size: 12,

                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(

              style:
                  softButtonStyle(),

              onPressed:
                  loading
                      ? null
                      : compressFiles,

              icon: loading

                  ? const SizedBox(

                      height: 18,
                      width: 18,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )

                  : const Icon(
                      Icons.compress),

              label: Text(

                loading

                    ? "Compressing..."

                    : "Compress Files",

              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMsg(String msg) {

    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(content: Text(msg)),
    );
  }
}