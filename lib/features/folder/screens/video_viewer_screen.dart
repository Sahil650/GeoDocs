import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoViewerScreen extends StatefulWidget {

  final String videoPath;
  final VoidCallback onDelete;

  final String? address;
  final double? lat;
  final double? lng;
  final String? dateTime;
  final String? timezone;

  const VideoViewerScreen({

    super.key,

    required this.videoPath,

    required this.onDelete,

    this.address,
    this.lat,
    this.lng,
    this.dateTime,
    this.timezone,
  });

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {

  late VideoPlayerController controller;

  @override
  void initState() {

    super.initState();

    controller = VideoPlayerController.file(

      File(widget.videoPath),

    )
      ..initialize().then((_) {

        setState(() {});

        controller.play();
      });

    controller.setLooping(true);
  }

  @override
  void dispose() {

    controller.dispose();

    super.dispose();
  }

  Future deleteVideo() async {

    await File(widget.videoPath).delete();

    widget.onDelete();

    if(mounted){

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        backgroundColor: Colors.black,

        actions: [

          IconButton(

            icon: const Icon(Icons.delete),

            onPressed: deleteVideo,
          ),
        ],
      ),

      body: Center(

        child: controller.value.isInitialized

            ? AspectRatio(

                aspectRatio: controller.value.aspectRatio,

                child: VideoPlayer(controller),

              )

            : const CircularProgressIndicator(),
      ),
    );
  }
}