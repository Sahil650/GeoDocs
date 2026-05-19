import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PhotoViewerScreen extends StatefulWidget {

  final String imagePath;
  final VoidCallback onDelete;

  final String? address;
  final double? lat;
  final double? lng;
  final String? dateTime;
  final String? timezone;

  const PhotoViewerScreen({

    super.key,

    required this.imagePath,
    required this.onDelete,

    this.address,
    this.lat,
    this.lng,
    this.dateTime,
    this.timezone,

  });

  @override
  State<PhotoViewerScreen> createState()
      => _PhotoViewerScreenState();

}

class _PhotoViewerScreenState
    extends State<PhotoViewerScreen> {

  Future shareImage() async {

    await Share.shareXFiles(

      [XFile(widget.imagePath)],

      text: "GeoTagged Photo",

    );

  }

  Future deleteImage() async {

    final confirm = await showDialog(

      context: context,

      builder: (_) => AlertDialog(

        title: const Text("Delete Photo"),

        actions: [

          TextButton(

            onPressed:
                ()=> Navigator.pop(context),

            child:
            const Text("Cancel"),

          ),

          TextButton(

            onPressed: () async {

              await File(widget.imagePath).delete();

              widget.onDelete();

              if(mounted){

                Navigator.pop(context);
                Navigator.pop(context);

              }

            },

            child:
            const Text("Delete"),

          ),

        ],

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed:
              ()=> Navigator.pop(context),

        ),

        actions: [

          IconButton(

            icon: const Icon(Icons.share),

            onPressed: shareImage,

          ),

          IconButton(

            icon: const Icon(

                Icons.delete,
                color: Colors.red),

            onPressed: deleteImage,

          ),

        ],

      ),

      extendBodyBehindAppBar: true,

      body: Center(

        child: Hero(

          tag: widget.imagePath,

          child: Image.file(

            File(widget.imagePath),

            fit: BoxFit.contain,

          ),

        ),

      ),

    );

  }

}