# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Keep Flutter related classes
-keep class io.flutter.** { *; }
-keep class com.airplay.padcast.receiver.** { *; }

# Keep native method names for Flutter plugins
-keepclassmembers class * {
    @io.flutter.embedding.engine.plugins.* *;
}

# Keep method channel names
-keepclassmembers class com.airplay.padcast.receiver.** {
    native <methods>;
}

# Ignore missing Google Play Core classes (not needed for our app)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }