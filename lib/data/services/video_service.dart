import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'location_service.dart';

class VideoService {
  static const String videoFolder = "/storage/emulated/0/DCIM/GeoTaggedVideos";
  static const int maxDurationSeconds = 300; // 5 minutes max

  final LocationService _locationService = LocationService();

  /// Get current geolocation data
  Future<Map<String, dynamic>> _getGeoData() async {
    try {
      final data = await _locationService.getLocationDetails();
      return {
        "lat": data["lat"],
        "lng": data["lng"],
        "address": data["address"],
        "dateTime": data["dateTime"],
        "timezone": "${data["timezone"]} | UTC ${data["utcTime"]}",
      };
    } catch (e) {
      return {
        "lat": 0.0,
        "lng": 0.0,
        "address": "Location Unavailable",
        "dateTime": DateTime.now().toString(),
        "timezone": "Unknown",
      };
    }
  }

  /// Ensure video folder exists
  Future<Directory> _ensureFolder() async {
    final folder = Directory(videoFolder);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  /// Start video recording
  Future<String> startRecording(CameraController controller) async {
    final folder = await _ensureFolder();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = "$videoFolder/${timestamp}_temp.mp4";

    await controller.startVideoRecording();
    return filePath;
  }

  /// Stop video recording and save with metadata
  Future<VideoResult> stopRecording(
    CameraController controller,
    String tempPath,
  ) async {
    try {
      // Stop recording
      final video = await controller.stopVideoRecording();

      // Get geolocation
      final geoData = await _getGeoData();

      // Generate final filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folder = await _ensureFolder();
      final finalPath = "${folder.path}/$timestamp.mp4";

      // Move video to final location
      final savedVideo = await File(video.path).copy(finalPath);

      // Delete temp file if different
      if (video.path != finalPath && await File(video.path).exists()) {
        await File(video.path).delete();
      }

      // Get video file size
      final fileSize = await savedVideo.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      // Save metadata JSON
      final metadata = {
        ...geoData,
        "filePath": finalPath,
        "fileSizeMB": fileSizeMB,
        "type": "video",
        "createdAt": DateTime.now().toIso8601String(),
      };

      final metaPath = finalPath.replaceAll('.mp4', '.json');
      await File(metaPath).writeAsString(jsonEncode(metadata));

      return VideoResult(
        success: true,
        videoPath: finalPath,
        metadata: metadata,
        errorMessage: null,
      );
    } catch (e) {
      return VideoResult(
        success: false,
        videoPath: null,
        metadata: null,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load video metadata from JSON file
  Future<Map<String, dynamic>?> loadMetadata(String videoPath) async {
    try {
      final metaPath = videoPath.replaceAll('.mp4', '.json');
      final metaFile = File(metaPath);

      if (await metaFile.exists()) {
        final jsonString = await metaFile.readAsString();
        return jsonDecode(jsonString);
      }
      return null;
    } catch (e) {
      debugPrint("Error loading metadata: $e");
      return null;
    }
  }

  /// Get all recorded videos
  Future<List<VideoItem>> getAllVideos() async {
    try {
      final folder = Directory(videoFolder);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final entities = await folder.list().toList();
      final videos = entities
          .where((e) => e.path.endsWith('.mp4'))
          .toList();

      final List<VideoItem> videoItems = [];

      for (var video in videos) {
        final meta = await loadMetadata(video.path);
        videoItems.add(VideoItem(
          path: video.path,
          metadata: meta,
          modified: File(video.path).statSync().modified,
        ));
      }

      // Sort by newest first
      videoItems.sort((a, b) => b.modified.compareTo(a.modified));

      return videoItems;
    } catch (e) {
      debugPrint("Error getting videos: $e");
      return [];
    }
  }

  /// Delete video and its metadata
  Future<bool> deleteVideo(String videoPath) async {
    try {
      final metaPath = videoPath.replaceAll('.mp4', '.json');

      if (await File(videoPath).exists()) {
        await File(videoPath).delete();
      }
      if (await File(metaPath).exists()) {
        await File(metaPath).delete();
      }
      return true;
    } catch (e) {
      debugPrint("Error deleting video: $e");
      return false;
    }
  }
}

/// Result after stopping video recording
class VideoResult {
  final bool success;
  final String? videoPath;
  final Map<String, dynamic>? metadata;
  final String? errorMessage;

  VideoResult({
    required this.success,
    this.videoPath,
    this.metadata,
    this.errorMessage,
  });
}

/// Video item with metadata for list/grid display
class VideoItem {
  final String path;
  final Map<String, dynamic>? metadata;
  final DateTime modified;

  VideoItem({
    required this.path,
    this.metadata,
    required this.modified,
  });

  String get address => metadata?['address'] ?? 'Unknown Location';
  String get dateTime => metadata?['dateTime'] ?? '';
  double get lat => metadata?['lat'] ?? 0.0;
  double get lng => metadata?['lng'] ?? 0.0;
  String get fileSizeMB => metadata?['fileSizeMB'] ?? '0';
}