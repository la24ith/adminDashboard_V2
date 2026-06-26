# Shared Preferences - سبب المشكلة الحقيقية
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keepclassmembers class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# Flutter Core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Google Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }


# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }