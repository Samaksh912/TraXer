# flutter_local_notifications serializes scheduled notifications with gson;
# R8 must not strip or rename these classes or pending reminders break.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-dontwarn com.google.android.play.core.**
