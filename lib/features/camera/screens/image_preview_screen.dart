import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {

  final String imagePath;
  final String address;
  final double lat;
  final double lng;
  final String dateTime;
  final String timezone;

  const ImagePreviewScreen({

    super.key,

    required this.imagePath,
    required this.address,
    required this.lat,
    required this.lng,
    required this.dateTime,
    required this.timezone,

  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        iconTheme:
        const IconThemeData(
            color: Colors.white),

      ),

      extendBodyBehindAppBar: true,

      body: Center(

        child: Hero(

          tag: imagePath,

          child: Image.file(

            File(imagePath),

            fit: BoxFit.contain,

          ),

        ),

      ),

    );

  }

}