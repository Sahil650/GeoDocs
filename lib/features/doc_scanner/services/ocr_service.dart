import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {

  static final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from image
  static Future<String> extractText(String imagePath) async {

    final inputImage =
        InputImage.fromFilePath(imagePath);

    final RecognizedText result =
        await _recognizer.processImage(inputImage);

    return result.text;
  }

  /// Close recognizer when app closes
  static void dispose(){

    _recognizer.close();
  }
}