####################################
# FLUTTER
####################################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
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

-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

####################################
# MULTIDEX
####################################
-keep class androidx.multidex.** { *; }

####################################
# GENERAL (EVITA CRASHEOS POR REFLECTION)
####################################
-keepattributes *Annotation*
-keepattributes Signature
