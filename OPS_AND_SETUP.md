# Operations & Deployment Guide

This guide covers the necessary steps to set up, secure, and deploy the Geo Tag Camera App.

---

## 🔑 Permissions Matrix

The app requires the following permissions to function correctly. Ensure these are enabled in your device settings.

| Permission | Usage | Required For |
| :--- | :--- | :--- |
| `CAMERA` | Captures raw images and video streams. | Camera Feature |
| `RECORD_AUDIO` | Captures audio for video recordings. | Video Mode |
| `ACCESS_FINE_LOCATION` | Streams high-precision GPS data. | Geotagging |
| `READ_EXTERNAL_STORAGE` | Browses existing media in the gallery. | Folder View |
| `WRITE_EXTERNAL_STORAGE` | Creates folders and saves media. | Saving Files |
| `MANAGE_EXTERNAL_STORAGE` | Required for Android 11+ folder creation. | Directory Sync |

---

## 🔥 Firebase Setup

The app uses Firebase for secure Authentication.

1.  **Project Creation**: Create a project in the [Firebase Console](https://console.firebase.google.com/).
2.  **Android Integration**:
    -   Add an Android app using your package name (`com.example.gps_map_camera_app`).
    -   Download `google-services.json` and place it in the `android/app/` directory.
3.  **Authentication**:
    -   Enable "Google Sign-In" and "Email/Password" in the Authentication dashboard.
    -   Configure your SHA-1 fingerprint for Google Sign-In support.

---

## 🏗 Build & Release

### Proguard / R8 (Android)
To keep the app size small and secure, Proguard is used. Ensure following rules are kept to prevent crashes with native libraries:
```pro
# Media3 Transformer
-keep class androidx.media3.transformer.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
```

### Signature Configuration
- Ensure your `key.properties` file is configured correctly for production builds.
- Run `flutter build apk --release` to generate the final deployment package.

---

## 📁 Troubleshooting Folder Creation
If folders are not appearing in the gallery:
1.  **Grant Permission**: Ensure "Manage All Files" permission is granted in the app info settings.
2.  **App Restart**: The app runs a `MediaScannerConnection` on startup to index the folders.
3.  **Manual Check**: Navigate to `Internal Storage > DCIM > GeoTaggedPhotos` using a file explorer.
