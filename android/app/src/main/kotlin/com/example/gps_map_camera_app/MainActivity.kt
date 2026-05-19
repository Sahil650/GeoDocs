package com.example.gps_map_camera_app

import android.content.Intent
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaScannerConnection
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val SHARE_CHANNEL         = "com.gps_map_camera_app/share"
        private const val EXIF_CHANNEL          = "exif_channel"
        private const val VIDEO_OVERLAY_CHANNEL = "video_overlay_channel"
        private const val MEDIA_SCAN_CHANNEL    = "com.gps_map_camera_app/media_scan"
        private const val PROGRESS_CHANNEL      = "com.gps_map_camera_app/video_progress"
    }

    /** EventSink that streams 0.0–1.0 progress values to Flutter */
    @Volatile
    private var progressSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── 1. Share channel ───────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "shareMedia") {
                    val videoPath = call.argument<String>("videoPath")
                    val mapPath   = call.argument<String>("mapPath")
                    val text      = call.argument<String>("text")
                    try {
                        val uris = ArrayList<Uri>()
                        videoPath?.let { uris.add(Uri.fromFile(File(it))) }
                        mapPath?.let   { uris.add(Uri.fromFile(File(it))) }
                        val shareIntent = Intent().apply {
                            action = Intent.ACTION_SEND_MULTIPLE
                            type   = "*/*"
                            putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                            putExtra(Intent.EXTRA_TEXT, text)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(shareIntent, "Share Video & Location Info"))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                } else result.notImplemented()
            }

        // ── 2. EXIF GPS writer ─────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXIF_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "writeExif") {
                    val path = call.argument<String>("path")
                    val lat  = call.argument<Double>("lat")
                    val lng  = call.argument<Double>("lng")
                    try {
                        val exif = ExifInterface(path!!)
                        exif.setLatLong(lat!!, lng!!)
                        exif.saveAttributes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EXIF_ERROR", e.message, null)
                    }
                } else result.notImplemented()
            }

        // ── 3. Progress EventChannel ───────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    progressSink = events
                }
                override fun onCancel(args: Any?) {
                    progressSink = null
                }
            })

        // ── 4. Video overlay channel (MediaCodec Pure Kotlin) ────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "burnOverlay") { result.notImplemented(); return@setMethodCallHandler }

                val inputPath   = call.argument<String>("inputPath")
                    ?: return@setMethodCallHandler result.error("ARG", "inputPath missing", null)
                val overlayPath = call.argument<String>("overlayPath")
                    ?: return@setMethodCallHandler result.error("ARG", "overlayPath missing", null)
                val outputPath  = call.argument<String>("outputPath")
                    ?: return@setMethodCallHandler result.error("ARG", "outputPath missing", null)
                val lat = call.argument<Double>("lat") ?: 0.0
                val lng = call.argument<Double>("lng") ?: 0.0

                CoroutineScope(Dispatchers.IO).launch {
                    val success = VideoOverlayMuxer.burn(
                        context     = applicationContext,
                        inputPath   = inputPath,
                        overlayPath = overlayPath,
                        outputPath  = outputPath,
                        lat         = lat,
                        lng         = lng,
                        progressCallback = { progress ->
                            CoroutineScope(Dispatchers.Main).launch {
                                progressSink?.success(progress)
                            }
                        }
                    )
                    CoroutineScope(Dispatchers.Main).launch {
                        progressSink?.success(1.0)
                        if (success) result.success(outputPath)
                        else         result.error("MUXER", "burnOverlay failed", null)
                    }
                }
            }

        // ── 5. Media scanner channel ───────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCAN_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFile") {
                    val path = call.argument<String>("path")
                        ?: return@setMethodCallHandler result.error("ARG", "path missing", null)
                    MediaScannerConnection.scanFile(applicationContext, arrayOf(path), null) { scanned, uri ->
                        CoroutineScope(Dispatchers.Main).launch {
                            result.success(uri?.toString() ?: scanned)
                        }
                    }
                } else result.notImplemented()
            }
    }
}