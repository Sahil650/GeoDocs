import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MapService {

  static Future<String> downloadMap(
      double lat,
      double lng
      ) async {

    final url =
        "https://staticmap.openstreetmap.de/staticmap.php"
        "?center=$lat,$lng"
        "&zoom=16"
        "&size=400x400"
        "&markers=$lat,$lng,red";

    final dir =
    await getTemporaryDirectory();

    final file =
    File("${dir.path}/map_${DateTime.now().millisecondsSinceEpoch}.png");

    final response =
    await http.get(Uri.parse(url));

    await file.writeAsBytes(response.bodyBytes);

    return file.path;
  }
}