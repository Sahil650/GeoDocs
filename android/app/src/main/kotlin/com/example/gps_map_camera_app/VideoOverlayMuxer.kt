package com.example.gps_map_camera_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

object VideoOverlayMuxer {
    private const val TAG = "VideoOverlayMuxer"

    fun burn(
        context: Context,
        inputPath: String,
        overlayPath: String,
        outputPath: String,
        lat: Double = 0.0,
        lng: Double = 0.0,
        progressCallback: ((Double) -> Unit)? = null
    ): Boolean {
        return try {
            runBlocking {
                _burn(context, inputPath, overlayPath, outputPath, lat, lng, progressCallback)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "burn() failed: ${e.message}", e)
            false
        }
    }

    @androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
    private suspend fun _burn(
        context: Context,
        inputPath: String,
        overlayPath: String,
        outputPath: String,
        lat: Double,
        lng: Double,
        progressCallback: ((Double) -> Unit)?
    ) {
        val baseBitmap = android.graphics.BitmapFactory.decodeFile(overlayPath)

        val retriever = android.media.MediaMetadataRetriever()
        retriever.setDataSource(inputPath)
        val vWidth = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 1080
        val vHeight = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 1920
        val rotationStr = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
        val rotation = rotationStr?.toInt() ?: 0
        retriever.release()

        val isPortrait = rotation == 90 || rotation == 270
        val finalWidth = if (isPortrait) vHeight else vWidth
        val finalHeight = if (isPortrait) vWidth else vHeight

        val fullScreenBitmap = android.graphics.Bitmap.createBitmap(finalWidth, finalHeight, android.graphics.Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(fullScreenBitmap)

        // Scale the overlay horizontally to fit within 1080p roughly, mimicking the Flutter UI (padding on both sides)
        val targetWidth = finalWidth - 64f
        val scaleRatio = targetWidth / baseBitmap.width.toFloat()
        val targetHeight = baseBitmap.height * scaleRatio

        val matrix = android.graphics.Matrix()
        matrix.postScale(scaleRatio, scaleRatio)
        
        // Position left = 32px, bottom margin = 80px
        val transX = 32f
        val transY = finalHeight - targetHeight - 80f
        matrix.postTranslate(transX, transY)

        canvas.drawBitmap(baseBitmap, matrix, null)

        val staticOverlay = object : BitmapOverlay() {
            override fun getBitmap(presentationTimeUs: Long): android.graphics.Bitmap {
                return fullScreenBitmap
            }
        }

        val overlayEffect = OverlayEffect(ImmutableList.of<androidx.media3.effect.TextureOverlay>(staticOverlay))
        val videoEffects = ImmutableList.of<Effect>(overlayEffect)
        val audioEffects = ImmutableList.of<androidx.media3.common.audio.AudioProcessor>()

        val effects = Effects(audioEffects, videoEffects)

        val inputUri = android.net.Uri.fromFile(java.io.File(inputPath)).toString()
        val editedMediaItem = EditedMediaItem.Builder(MediaItem.fromUri(inputUri))
            .setEffects(effects)
            .build()

        val deferred = CompletableDeferred<Boolean>()

        kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
            val transformer = Transformer.Builder(context)
                .setVideoMimeType(androidx.media3.common.MimeTypes.VIDEO_H264)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                        deferred.complete(true)
                    }

                    override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                        Log.e(TAG, "Transformer error: ${exportException.message}", exportException)
                        deferred.completeExceptionally(exportException)
                    }
                })
                .build()

            transformer.start(editedMediaItem, outputPath)

            // Poll progress for the Flutter UI on the main thread
            kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main).launch {
                while (!deferred.isCompleted) {
                    val progressHolder = ProgressHolder()
                    val state = transformer.getProgress(progressHolder)
                    
                    if (state == Transformer.PROGRESS_STATE_AVAILABLE) {
                        val p = progressHolder.progress / 100.0
                        progressCallback?.invoke(p.coerceIn(0.0, 0.99))
                    }
                    kotlinx.coroutines.delay(100)
                }
            }
        }

        deferred.await()
        baseBitmap.recycle()
        fullScreenBitmap.recycle()
        Log.d(TAG, "Transformer completed successfully to $outputPath")
    }
}