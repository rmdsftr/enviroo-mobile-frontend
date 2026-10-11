# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings { <fields>; }

# Play Core (referenced by Flutter embedding but not used — suppress R8 missing class errors)
-dontwarn com.google.android.play.core.**
