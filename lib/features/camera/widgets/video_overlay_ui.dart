import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class VideoOverlayUI extends StatelessWidget {
  final bool isRecording;
  final Duration recordingDuration;
  final VoidCallback onToggleRecording;
  final VoidCallback onPreviewTap;
  final String? lastVideoPath;
  final VoidCallback onPhotoTap;
  final VoidCallback onFlashToggle;
  final FlashMode flashMode;
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const VideoOverlayUI({
    super.key,
    required this.isRecording,
    required this.recordingDuration,
    required this.onToggleRecording,
    required this.onPreviewTap,
    this.lastVideoPath,
    required this.onPhotoTap,
    required this.onFlashToggle,
    required this.flashMode,
    required this.zoom,
    required this.onZoomChanged,
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
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "VIDEO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),

          if (isRecording)
            Positioned(
              top: 10,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.green, size: 20),
              ),
            ),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [zoomButton(1), zoomButton(2), zoomButton(4)],
            ),
          ),

          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PREVIEW BUTTON (Updated with ValueKey)
                GestureDetector(
                  onTap: onPreviewTap,
                  child: Container(
                    key: ValueKey(lastVideoPath), // Forces UI update when video saves
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white),
                    ),
                    child: lastVideoPath != null
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        : const Icon(Icons.video_library, color: Colors.white, size: 28),
                  ),
                ),

                // RECORD/STOP BUTTON
                GestureDetector(
                  onTap: onToggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isRecording ? Colors.white : Colors.red,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isRecording ? 32 : 56,
                        height: isRecording ? 32 : 56,
                        decoration: BoxDecoration(
                          color: isRecording ? Colors.red : Colors.white,
                          borderRadius: isRecording 
                              ? BorderRadius.circular(6) 
                              : BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ),

                // SWITCH TO PHOTO MODE
                GestureDetector(
                  onTap: onPhotoTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
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