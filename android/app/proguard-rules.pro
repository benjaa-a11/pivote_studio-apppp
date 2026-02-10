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
# GENERAL
####################################
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
