import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../../data/services/storage_service.dart';
import '../../camera/services/media_scanner_service.dart';

class ImageCompressScreen extends StatefulWidget {

  const ImageCompressScreen({super.key});

  @override
  State<ImageCompressScreen> createState() =>
      _ImageCompressScreenState();
}

class _ImageCompressScreenState
    extends State<ImageCompressScreen> {

  List<File> selectedFiles = [];

  int quality = 70;

  bool loading = false;

  ButtonStyle softButtonStyle() {

    return ElevatedButton.styleFrom(

      elevation: 0,

      backgroundColor:
          Colors.grey.shade100,

      foregroundColor:
          Colors.black87,

      padding:
          const EdgeInsets.symmetric(
              vertical: 14),

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(30),

      ),
    );
  }

  Future<void> pickImages() async {

    final picker = ImagePicker();

    final picked =
        await picker.pickMultiImage();

    if (picked.isEmpty) return;

    setState(() {

      for (var file in picked) {

        selectedFiles.add(
            File(file.path));

      }

    });

  }

  void removeImage(int index) {

    setState(() {

      selectedFiles.removeAt(index);

    });

  }

  void clearAll() {

    setState(() {

      selectedFiles.clear();

    });

  }

  Future<void> compressImages() async {

    if (selectedFiles.isEmpty) return;

    setState(() => loading = true);

    final dir = await StorageService.getConvertedDirectory();

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (int i = 0;
        i < selectedFiles.length;
        i++) {

      final bytes =
          await selectedFiles[i]
              .readAsBytes();

      final result = await compute(

        processImage,

        {

          "bytes": bytes,

          "quality": quality,

        },

      );

      final path =

          "${dir.path}/COMP_${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

      await File(path)
          .writeAsBytes(result);

      // Notify MediaScanner
      await MediaScannerService.scanFile(path);

    }

    setState(() => loading = false);

    showMsg(
        "Compressed images saved");

  }

  static List<int> processImage(

      Map<String, dynamic> map) {

    final bytes = map["bytes"];

    final int quality =
        map["quality"];

    img.Image? image =
        img.decodeImage(bytes);

    return img.encodeJpg(

      image!,

      quality: quality,

    );

  }

  void showMsg(String msg) {

    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(

        content: Text(msg),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:
            const Text("Compress Images"),

        actions: [

          if (selectedFiles.isNotEmpty)

            IconButton(

              icon:
                  const Icon(Icons.delete),

              onPressed: clearAll,

            ),

        ],

      ),

      body: SingleChildScrollView(

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

                  "Images (${selectedFiles.length})",

                  style:
                      const TextStyle(

                    fontSize: 16,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                ElevatedButton.icon(

                  onPressed: pickImages,

                  icon: const Icon(
                      Icons.add_photo_alternate),

                  label:
                      const Text("Add Images"),

                ),

              ],

            ),

            const SizedBox(height: 12),

            if (selectedFiles.isEmpty)

              Container(

                height: 180,

                alignment:
                    Alignment.center,

                decoration:

                    BoxDecoration(

                  color: Colors.grey[300],

                  borderRadius:
                      BorderRadius.circular(
                          12),

                ),

                child: const Text(
                    "No Images Selected"),

              )

            else

              SizedBox(

                height: 200,

                child: GridView.builder(

                  scrollDirection:
                      Axis.horizontal,

                  gridDelegate:

                      const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount: 1,

                    mainAxisSpacing: 8,

                  ),

                  itemCount:
                      selectedFiles.length,

                  itemBuilder:
                      (context, index) {

                    return Stack(

                      children: [

                        ClipRRect(

                          borderRadius:
                              BorderRadius.circular(
                                  8),

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

                          child:
                              GestureDetector(

                            onTap: () =>
                                removeImage(
                                    index),

                            child:
                                const CircleAvatar(

                              radius: 12,

                              backgroundColor:
                                  Colors.red,

                              child: Icon(

                                Icons.close,

                                size: 14,

                                color:
                                    Colors.white,

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

            Text("Quality: $quality"),

            Slider(

              value:
                  quality.toDouble(),

              min: 20,

              max: 100,

              divisions: 8,

              label: "$quality",

              onChanged: (v) {

                setState(

                    () =>
                        quality =
                            v.round());

              },

            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(

              style:
                  softButtonStyle(),

              onPressed:
                  loading
                      ? null
                      : compressImages,

              icon: loading

                  ? const SizedBox(

                      width: 18,

                      height: 18,

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

                    : "Compress Images",

              ),

            ),

          ],

        ),

      ),

    );

  }

}