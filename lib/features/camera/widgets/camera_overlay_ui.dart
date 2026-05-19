import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraOverlayUI extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onFlashToggle;
  final FlashMode flashMode;
  final double zoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback? onPreviewTap;
  final String? lastImagePath;
  final VoidCallback onVideoTap;

  const CameraOverlayUI({
    super.key,
    required this.onCapture,
    required this.onFlashToggle,
    required this.flashMode,
    required this.zoom,
    required this.onZoomChanged,
    this.onPreviewTap,
    this.lastImagePath,
    required this.onVideoTap,
  });

  IconData getFlashIcon() {
    switch (flashMode) {
      case FlashMode.torch: return Icons.flash_on;
      case FlashMode.auto: return Icons.flash_auto;
      default: return Icons.flash_off;
    }
  }

  Widget zoomButton(double value) {
    return GestureDetector(
      onTap: () => onZoomChanged(value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: zoom == value ? Colors.white : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "${value.toStringAsFixed(0)}x",
          style: TextStyle(
            color: zoom == value ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // ZOOM BUTTONS
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [zoomButton(1), zoomButton(2), zoomButton(4)],
            ),
          ),

          // BOTTOM CONTROLS
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PREVIEW / GALLERY BUTTON
                GestureDetector(
                  onTap: onPreviewTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white),
                    ),
                    child: lastImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(
                              File(lastImagePath!),
                              fit: BoxFit.cover,
                              key: ValueKey(lastImagePath),
                            ),
                          )
                        : const Icon(Icons.photo_library, color: Colors.white, size: 28),
                  ),
                ),

                // CAPTURE BUTTON
                GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Center(
                      child: CircleAvatar(radius: 28, backgroundColor: Colors.white),
                    ),
                  ),
                ),

                // VIDEO MODE BUTTON
                GestureDetector(
                  onTap: onVideoTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}