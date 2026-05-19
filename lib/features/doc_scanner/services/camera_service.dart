import 'package:camera/camera.dart';

class CameraService {

  late CameraController controller;

  Future init() async {

    final cameras = await availableCameras();

    controller = CameraController(

      cameras.first,

      ResolutionPreset.high,

      enableAudio: false,
    );

    await controller.initialize();
  }

  Future<String?> capture() async {

    final file = await controller.takePicture();

    return file.path;
  }
}