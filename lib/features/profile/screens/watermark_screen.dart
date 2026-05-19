
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() =>
      _WatermarkScreenState();
}

class _WatermarkScreenState
    extends State<WatermarkScreen> {

  File? image;

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  /// load saved watermark or default logo
  Future loadImage() async {

    final prefs =
        await SharedPreferences.getInstance();

    final savedPath =
        prefs.getString("watermark");

    /// if user selected logo before
    if (savedPath != null &&
        File(savedPath).existsSync()) {

      setState(() {
        image = File(savedPath);
      });

    }

    /// otherwise load default logo
    else {

      final bytes =
          await rootBundle.load(
        "assets/watermark/default_logo.png",
      );

      final dir =
          await getTemporaryDirectory();

      final file =
          File("${dir.path}/default_logo.png");

      await file.writeAsBytes(
          bytes.buffer.asUint8List());

      setState(() {
        image = file;
      });

    }

  }

  /// pick custom logo
  Future pickImage() async {

    final picker = ImagePicker();

    final picked =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
        "watermark", picked.path);

    setState(() {
      image = File(picked.path);
    });

  }

  /// remove custom logo → revert to default
  Future removeImage() async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove("watermark");

    await loadImage();

  }

  @override
  Widget build(BuildContext context) {

    final width =
        MediaQuery.of(context).size.width;

    final isTablet = width > 600;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Watermark"),
      ),

      body: Center(

        child: Container(

          width:
              isTablet ? 500 : double.infinity,

          padding:
              const EdgeInsets.all(16),

          child: Column(

            children: [

              /// preview box
              Container(

                height: 180,

                width: double.infinity,

                decoration: BoxDecoration(

                  border:
                      Border.all(
                          color: Colors.grey),

                  borderRadius:
                      BorderRadius.circular(12),

                ),

                child: image == null

                    ? const Center(
                        child: Text(
                            "No watermark"),
                      )

                    : ClipRRect(

                        borderRadius:
                            BorderRadius.circular(12),

                        child: Image.file(

                          image!,

                          fit: BoxFit.contain,

                        ),

                      ),

              ),

              const SizedBox(height: 20),

              /// select logo
              SizedBox(

                width: double.infinity,

                child: ElevatedButton.icon(

                  onPressed: pickImage,

                  icon:
                      const Icon(Icons.upload),

                  label:
                      const Text("Change Logo"),

                ),

              ),

              const SizedBox(height: 10),

              /// reset default
              SizedBox(

                width: double.infinity,

                child: ElevatedButton(

                  onPressed: removeImage,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.grey,
                  ),

                  child:
                      const Text("Reset Default"),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}