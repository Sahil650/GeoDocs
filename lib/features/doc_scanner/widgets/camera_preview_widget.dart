import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {

  final CameraController? controller;

  const CameraPreviewWidget({

    super.key,

    this.controller,
  });

  @override
  Widget build(BuildContext context) {

    if (controller == null ||

        !controller!.value.isInitialized) {

      return const Center(

        child: CircularProgressIndicator(),
      );
    }

    return CameraPreview(controller!);
  }
}