# Add project specific ProGuard rules here.

# Media3 / ExoPlayer - CRITICAL: No ofuscar estas clases
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Mantener clases de DRM
-keep class * implements androidx.media3.exoplayer.drm.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Tu aplicación - Actualiza con tu package
-keep class com.example.pivote_studio.** { *; }

# Mantener MethodChannel handlers
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel.Result *;
}

# Mantener PlatformView
-keep class * implements io.flutter.plugin.platform.PlatformView { *; }