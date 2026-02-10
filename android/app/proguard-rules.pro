####################################
# FLUTTER
####################################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-dontwarn io.flutter.embedding.**

####################################
# FIREBASE / GOOGLE
####################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

####################################
# MEDIA3 / EXOPLAYER
####################################
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Keep DRM-related classes (CRITICAL for ClearKey)
-keep class androidx.media3.exoplayer.drm.** { *; }
-keep interface androidx.media3.exoplayer.drm.** { *; }

-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

####################################
# CUSTOM CLASSES (Pivote Studio)
####################################
-keep class com.example.pivote_studio.ClearKeyDrmCallback { *; }
-keep class com.example.pivote_studio.PlayerConfig { *; }
-keep class com.example.pivote_studio.ExoPlayerView { *; }
-keep class com.example.pivote_studio.ExoPlayerViewFactory { *; }

####################################
# MULTIDEX
####################################
-keep class androidx.multidex.** { *; }

####################################
# GENERAL (EVITA CRASHEOS POR REFLECTION)
####################################
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

####################################
# OPTIMIZATIONS (Release only)
####################################
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
