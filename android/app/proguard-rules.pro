# Flutter Wrapper Rules

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Flutter embedder (engine) classes
-keep class io.flutter.embedding.engine.FlutterJNI { *; }

# Prevent obfuscation of specific Flutter entry points
-keep class com.example.my_app.MainActivity { *; }

# Generic Dart-related keeps (often handled by the R8 compiler automatically for Flutter, but good to be safe)
# -keep class * extends io.flutter.embedding.android.FlutterActivity
# -keep class * extends io.flutter.embedding.android.FlutterFragment
# -keep class * extends io.flutter.plugin.common.PluginRegistry$Registrar

# Keep standard Android classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Support for reflection-heavy libraries (adjust as needed based on dependencies)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Don't warn about missing classes from optional dependencies
-dontwarn io.flutter.**
