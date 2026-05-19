# ML Kit Text Recognition fix
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# prevent removing language recognizers
-keep class com.google.mlkit.vision.text.** { *; }

# keep annotations
-keepattributes *Annotation*

# keep generic signatures
-keepattributes Signature

# Flutter
-keep class io.flutter.** { *; }

# CameraX
-keep class androidx.camera.** { *; }

# ML Kit Text Recognition - Ignore missing language models
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.latin.**

# Google Play Core rules
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**