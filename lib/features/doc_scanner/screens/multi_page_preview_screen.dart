import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../../main.dart';

import '../services/pdf_service.dart';
import '../services/watermark_service.dart';
import 'document_viewer_screen.dart';

class MultiPagePreviewScreen extends StatefulWidget {

  final List<String> pages;

  final String address;
  final double lat;
  final double lng;

  const MultiPagePreviewScreen({
    super.key,
    required this.pages,
    required this.address,
    required this.lat,
    required this.lng,
  });

  @override
  State<MultiPagePreviewScreen> createState() =>
      _MultiPagePreviewScreenState();
}

class _MultiPagePreviewScreenState
    extends State<MultiPagePreviewScreen> {

  late List<String> pages;

  @override
  void initState() {

    super.initState();

    pages = List.from(widget.pages);

  }

  void deletePage(int index) {

    pages.removeAt(index);

    Navigator.pop(context, pages);

  }

  Future<void> combinePdf() async {

    try {

      List<String> watermarkedImages = [];

      for (String imgPath in pages) {

        final wm =
        await WatermarkService.addGeoWatermark(

          imagePath: imgPath,

          address: widget.address,

          lat: widget.lat,

          lng: widget.lng,

        );

        watermarkedImages.add(wm.path);

      }

      final pdfPath =
      await PdfService.createPdf(

        watermarkedImages,

      );

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content:
          Text("PDF saved\n$pdfPath"),

        ),

      );

    }

    catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content:
          Text("Error $e"),

        ),

      );

    }

  }

  @override
  Widget build(BuildContext context) {

    final screenWidth =
    MediaQuery.of(context).size.width;

    final screenHeight =
    MediaQuery.of(context).size.height;

    int crossAxisCount = 2;

    if (screenWidth > 900) {

      crossAxisCount = 4;

    }

    else if (screenWidth > 600) {

      crossAxisCount = 3;

    }

    double padding =
    screenWidth * 0.04;

    double spacing =
    screenWidth * 0.03;

    double buttonHeight =
    screenHeight * 0.065;

    return Scaffold(

      backgroundColor:
      const Color(0xffF5F7FB),

      appBar: AppBar(

        backgroundColor:
        Colors.white,

        elevation: 0,

        title: const Text(

          "Document Pages",

          style: TextStyle(
            color: Colors.black,
          ),

        ),

        iconTheme:
        const IconThemeData(

          color: Colors.black,

        ),

        leading: IconButton(

          icon:
          const Icon(Icons.arrow_back),

          onPressed: () {

            Navigator.pop(context, pages);

          },

        ),

      ),

      body: Column(

        children: [

          Expanded(

            child:
            ReorderableGridView.builder(

              padding:
              EdgeInsets.all(padding),

              itemCount:
              pages.length + 1,

              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount:
                crossAxisCount,

                crossAxisSpacing:
                spacing,

                mainAxisSpacing:
                spacing,

                childAspectRatio: .72,

              ),

              onReorder:
                  (oldIndex, newIndex) {

                if (oldIndex < pages.length &&
                    newIndex < pages.length) {

                  setState(() {

                    final item =
                    pages.removeAt(oldIndex);

                    pages.insert(newIndex, item);

                  });

                }

              },

              itemBuilder: (_, i) {

                if (i == pages.length) {

                  return GestureDetector(

                    key:
                    const ValueKey("insert"),

                    onTap: () {

                      Navigator.pop(context, pages);

                    },

                    child: Container(

                      decoration:
                      BoxDecoration(

                        color: Colors.white,

                        borderRadius:
                        BorderRadius.circular(16),

                        border: Border.all(

                          color:
                          Colors.blue
                              .withOpacity(.25),

                        ),

                      ),

                      child:
                      Column(

                        mainAxisAlignment:
                        MainAxisAlignment.center,

                        children: [

                          Icon(

                            Icons.add,

                            size:
                            screenWidth * 0.08,

                            color:
                            Colors.blue,

                          ),

                          SizedBox(

                            height:
                            screenHeight * 0.01,

                          ),

                          Text(

                            "INSERT PAGE",

                            style: TextStyle(

                              fontWeight:
                              FontWeight.w600,

                              color:
                              Colors.blue,

                              fontSize:
                              screenWidth * 0.035,

                            ),

                          )

                        ],

                      ),

                    ),

                  );

                }

                return GestureDetector(

                  key:
                  ValueKey(pages[i]),

                  onTap: () async {

                    final updatedPages =
                    await Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            DocumentViewerScreen(

                              pages: pages,

                              initialIndex: i,

                            ),

                      ),

                    );

                    if (updatedPages != null) {

                      setState(() {

                        pages =
                            List<String>.from(
                                updatedPages);

                      });

                    }

                  },

                  child: Container(

                    decoration:
                    BoxDecoration(

                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(16),

                      boxShadow: [

                        BoxShadow(

                          blurRadius: 6,

                          color:
                          Colors.black
                              .withOpacity(.05),

                          offset:
                          const Offset(0, 4),

                        )

                      ],

                    ),

                    child: Stack(

                      children: [

                        Column(

                          children: [

                            Expanded(

                              child:
                              ClipRRect(

                                borderRadius:
                                const BorderRadius.vertical(

                                  top:
                                  Radius.circular(16),

                                ),

                                child:
                                Image.file(

                                  File(
                                      pages[i]),

                                  fit:
                                  BoxFit.cover,

                                  width:
                                  double.infinity,

                                ),

                              ),

                            ),

                            Padding(

                              padding:
                              EdgeInsets.all(

                                  screenWidth *
                                      0.02),

                              child:
                              Text(

                                "Page ${i + 1}",

                                style:
                                TextStyle(

                                  fontWeight:
                                  FontWeight.w600,

                                  fontSize:
                                  screenWidth *
                                      0.035,

                                ),

                              ),

                            ),

                          ],

                        ),

                        Positioned(

                          left: 8,
                          top: 8,

                          child:
                          Container(

                            padding:
                            EdgeInsets.all(

                                screenWidth *
                                    0.015),

                            decoration:
                            const BoxDecoration(

                              color:
                              Colors.blue,

                              shape:
                              BoxShape.circle,

                            ),

                            child:
                            Text(

                              "${i + 1}",

                              style:
                              TextStyle(

                                color:
                                Colors.white,

                                fontSize:
                                screenWidth *
                                    0.03,

                              ),

                            ),

                          ),

                        ),

                        Positioned(

                          right: 6,
                          top: 6,

                          child:
                          GestureDetector(

                            onTap: () =>
                                deletePage(i),

                            child:
                            CircleAvatar(

                              radius:
                              screenWidth *
                                  0.03,

                              backgroundColor:
                              Colors.red,

                              child:
                              Icon(

                                Icons.close,

                                size:
                                screenWidth *
                                    0.03,

                                color:
                                Colors.white,

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                );

              },

            ),

          ),

          SizedBox(

              height:
              screenHeight * 0.01),

          GestureDetector(

            onTap: combinePdf,

            child: Container(

              margin:
              EdgeInsets.symmetric(

                horizontal:
                padding,

              ),

              height:
              buttonHeight,

              decoration:
              BoxDecoration(

                borderRadius:
                BorderRadius.circular(14),

                gradient:
                const LinearGradient(

                  colors: [

                    Color(0xff27C2A0),

                    Color(0xff2ED3C6),

                  ],

                ),

              ),

              child:
              Center(

                child:
                Row(

                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    Icon(

                      Icons.picture_as_pdf,

                      color:
                      Colors.white,

                      size:
                      screenWidth *
                          0.05,

                    ),

                    SizedBox(

                      width:
                      screenWidth *
                          0.02,

                    ),

                    Text(

                      "COMBINE TO PDF",

                      style:
                      TextStyle(

                        color:
                        Colors.white,

                        fontWeight:
                        FontWeight.bold,

                        fontSize:
                        screenWidth *
                            0.04,

                      ),

                    ),

                  ],

                ),

              ),

            ),

          ),

          SizedBox(
            height:
            MediaQuery.of(context)
                .padding
                .bottom +
                16,
          ),

        ],

      ),

      bottomNavigationBar:
      BottomNavigationBar(

        currentIndex: 1,

        onTap: (index) {

          Navigator.pushAndRemoveUntil(

            context,

            MaterialPageRoute(

              builder: (_) =>
              const MainScreen(),

            ),

                (route) => false,

          );

        },

        type:
        BottomNavigationBarType.fixed,

        selectedItemColor:
        Colors.deepPurple,

        unselectedItemColor:
        Colors.grey,

        items: const [

          BottomNavigationBarItem(

            icon:
            Icon(Icons.folder),

            label:
            "Folder",

          ),

          BottomNavigationBarItem(

            icon:
            Icon(Icons.document_scanner),

            label:
            "Scanner",

          ),

          BottomNavigationBarItem(

            icon:
            Icon(Icons.camera_alt),

            label:
            "Camera",

          ),

          BottomNavigationBarItem(

            icon:
            Icon(Icons.sync),

            label:
            "Convert",

          ),

          BottomNavigationBarItem(

            icon:
            Icon(Icons.person),

            label:
            "Profile",

          ),

        ],

      ),

    );

  }

}