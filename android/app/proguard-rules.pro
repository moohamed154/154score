# Google Play Core & Deferred Components (prevents R8 missing class errors)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
-ignorewarnings

# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Workmanager & Notifications Rules
-keep class androidx.work.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Security & Crypto Protection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}

# Preserve native JNI / FFI methods
-keepclasseswithmembernames class * {
    native <methods>;
}
