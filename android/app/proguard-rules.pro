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
# MULTIDEX
####################################
-keep class androidx.multidex.** { *; }

####################################
# MEDIA3 / EXOPLAYER
####################################
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

####################################
# GENERAL
####################################
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
