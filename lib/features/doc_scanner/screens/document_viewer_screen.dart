import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DocumentViewerScreen extends StatefulWidget {

  final List<String> pages;
  final int initialIndex;

  const DocumentViewerScreen({
    super.key,
    required this.pages,
    required this.initialIndex,
  });

  @override
  State<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState
    extends State<DocumentViewerScreen> {

  late List<String> pages;
  late PageController controller;

  int index = 0;

  bool cropMode = false;

  List<Offset> cropPoints = [];

  @override
  void initState() {

    super.initState();

    pages = List.from(widget.pages);

    index = widget.initialIndex;

    controller =
        PageController(initialPage: index);

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      initCrop();

    });

  }

  void initCrop() {

    final size =
        MediaQuery.of(context).size;

    cropPoints = [

      Offset(size.width * .12,
          size.height * .22),

      Offset(size.width * .88,
          size.height * .22),

      Offset(size.width * .12,
          size.height * .75),

      Offset(size.width * .88,
          size.height * .75),

    ];

    setState(() {});

  }

  Future rotate() async {

    final file =
        File(pages[index]);

    final image =
        img.decodeImage(
            await file.readAsBytes())!;

    final rotated =
        img.copyRotate(image, angle: 90);

    final newFile =
        await _createNewFile();

    await newFile.writeAsBytes(
        img.encodeJpg(rotated));

    setState(() {

      pages[index] =
          newFile.path;

    });

  }

  Future applyCrop() async {

    final file =
        File(pages[index]);

    final image =
        img.decodeImage(
            await file.readAsBytes())!;

    final screenSize =
        MediaQuery.of(context).size;

    final imageRatio =
        image.width / image.height;

    final screenRatio =
        screenSize.width /
            screenSize.height;

    double displayedWidth;
    double displayedHeight;

    if (imageRatio > screenRatio) {

      displayedWidth =
          screenSize.width;

      displayedHeight =
          displayedWidth /
              imageRatio;

    } else {

      displayedHeight =
          screenSize.height;

      displayedWidth =
          displayedHeight *
              imageRatio;

    }

    final offsetX =
        (screenSize.width -
            displayedWidth) / 2;

    final offsetY =
        (screenSize.height -
            displayedHeight) / 2;

    final scaleX =
        image.width / displayedWidth;

    final scaleY =
        image.height / displayedHeight;

    final cropX =
        ((cropPoints[0].dx - offsetX) * scaleX)
            .clamp(0, image.width);

    final cropY =
        ((cropPoints[0].dy - offsetY) * scaleY)
            .clamp(0, image.height);

    final cropW =
        ((cropPoints[1].dx -
            cropPoints[0].dx) *
            scaleX)
            .abs();

    final cropH =
        ((cropPoints[2].dy -
            cropPoints[0].dy) *
            scaleY)
            .abs();

    final cropped =
        img.copyCrop(

          image,

          x: cropX.toInt(),

          y: cropY.toInt(),

          width: cropW.toInt(),

          height: cropH.toInt(),

        );

    final newFile =
        await _createNewFile();

    await newFile.writeAsBytes(
        img.encodeJpg(cropped));

    setState(() {

      pages[index] =
          newFile.path;

      cropMode = false;

    });

  }

  Future<File> _createNewFile() async {

    final dir =
        await getTemporaryDirectory();

    final path =
        "${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg";

    return File(path);

  }

  void deletePage() {

    pages.removeAt(index);

    Navigator.pop(context, pages);

  }

  Widget corner(int i) {

    return Positioned(

      left: cropPoints[i].dx - 15,
      top: cropPoints[i].dy - 15,

      child: GestureDetector(

        onPanUpdate: (d) {

          setState(() {

            cropPoints[i] = Offset(

              cropPoints[i].dx +
                  d.delta.dx,

              cropPoints[i].dy +
                  d.delta.dy,

            );

          });

        },

        child: Container(

          width: 30,
          height: 30,

          decoration: BoxDecoration(

            border: Border.all(
                color: Colors.white,
                width: 2),

          ),

        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        backgroundColor: Colors.black,

        title: Text(

          "Page ${index + 1}",

          style:
          const TextStyle(
              color: Colors.white),

        ),

      ),

      body: Stack(

        children: [

          PageView.builder(

            controller: controller,

            itemCount:
            pages.length,

            onPageChanged: (i) {

              setState(() {

                index = i;

                initCrop();

              });

            },

            itemBuilder: (_, i) {

              return Stack(

                children: [

                  Center(

                    child: Image.file(

                      File(pages[i]),

                      key:
                      ValueKey(pages[i]),

                      fit:
                      BoxFit.contain,

                    ),

                  ),

                  if (cropMode)
                    CustomPaint(

                      size:
                      MediaQuery.of(context).size,

                      painter:
                      CropPainter(cropPoints),

                    ),

                  if (cropMode)
                    ...List.generate(
                        4, corner),

                ],

              );

            },

          ),

          Positioned(

            bottom:
            MediaQuery.of(context)
                .padding
                .bottom +
                12,

            left: 0,
            right: 0,

            child: Container(

              padding:
              const EdgeInsets.symmetric(
                  vertical: 14),

              decoration:
              const BoxDecoration(

                color: Colors.black,

                border: Border(

                  top: BorderSide(
                      color:
                      Colors.white12),

                ),

              ),

              child: Row(

                mainAxisAlignment:
                MainAxisAlignment
                    .spaceEvenly,

                children: [

                  toolBtn(

                    Icons.crop,

                    cropMode
                        ? "Apply"
                        : "Crop",

                        () {

                      if (cropMode) {

                        applyCrop();

                      } else {

                        setState(() {

                          cropMode = true;

                        });

                      }

                    },

                  ),

                  toolBtn(
                      Icons.rotate_right,
                      "Rotate",
                      rotate),

                  toolBtn(
                      Icons.delete,
                      "Delete",
                      deletePage),

                  toolBtn(

                    Icons.check,

                    "Done",

                        () {

                      Navigator.pop(
                          context,
                          pages);

                    },

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget toolBtn(

      IconData icon,
      String text,
      VoidCallback onTap,

      ) {

    return GestureDetector(

      onTap: onTap,

      child: Column(

        children: [

          Icon(icon,
              color: Colors.white),

          const SizedBox(height: 4),

          Text(

            text,

            style:
            const TextStyle(

              color: Colors.white,
              fontSize: 12,

            ),

          ),

        ],

      ),

    );

  }

}

class CropPainter extends CustomPainter {

  final List<Offset> points;

  CropPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {

    final overlayPaint =
    Paint()
      ..color =
      Colors.black.withOpacity(.55);

    final borderPaint =
    Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style =
      PaintingStyle.stroke;

    canvas.saveLayer(
        Offset.zero & size,
        Paint());

    canvas.drawRect(
        Offset.zero & size,
        overlayPaint);

    final cropPath =
    Path()

      ..moveTo(points[0].dx,
          points[0].dy)

      ..lineTo(points[1].dx,
          points[1].dy)

      ..lineTo(points[3].dx,
          points[3].dy)

      ..lineTo(points[2].dx,
          points[2].dy)

      ..close();

    canvas.drawPath(

        cropPath,

        Paint()
          ..blendMode =
          BlendMode.clear

    );

    canvas.restore();

    canvas.drawPath(
        cropPath,
        borderPaint);

  }

  @override
  bool shouldRepaint(oldDelegate) => true;

}