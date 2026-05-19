import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String appFolderName = "GeoTaggedPhotos";
  static const String scanFolderName = "GeoScanner";
  static const String exportFolderName = "GeoTag";

  /// Resolves the base directory for media storage.
  /// On Android, it attempts to find the DCIM/Documents/Download folders in the public external storage.
  /// On iOS, it uses the application documents directory.
  static Future<Directory> _getAndroidRootDir(String publicDir) async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final List<String> paths = externalDir.path.split("/");
        final int androidIndex = paths.indexOf("Android");
        if (androidIndex != -1) {
          final String rootPath = paths.sublist(0, androidIndex).join("/");
          return Directory("$rootPath/$publicDir");
        }
      }
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  /// Returns the main directory for photos and videos.
  static Future<Directory> getPhotoDirectory() async {
    final base = await _getAndroidRootDir("DCIM");
    final dir = Directory("${base.path}/$appFolderName");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the directory for scanned documents.
  static Future<Directory> getDocDirectory() async {
    final base = await _getAndroidRootDir("Documents");
    final dir = Directory("${base.path}/$scanFolderName");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the directory for converted files (images/comp).
  static Future<Directory> getConvertedDirectory() async {
    final base = await _getAndroidRootDir("DCIM");
    final dir = Directory("${base.path}/GeoTag/Converted");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the directory for exports (PDF/Word/GPX/KML).
  static Future<Directory> getExportDirectory() async {
    final base = await _getAndroidRootDir("Download");
    final dir = Directory("${base.path}/$exportFolderName");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Helper to get all relevant directories for the Folder view
  static Future<Map<String, Directory>> getAllDirectories() async {
    return {
      'photos': await getPhotoDirectory(),
      'docs': await getDocDirectory(),
      'converted': await getConvertedDirectory(),
      'exports': await getExportDirectory(),
    };
  }
}