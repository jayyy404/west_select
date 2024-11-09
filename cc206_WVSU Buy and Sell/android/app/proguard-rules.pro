# Firebase rules
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }

# Firebase Firestore (example)
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.auth.** { *; }

# Keep other important classes or libraries you use
-keep class com.facebook.** { *; }

# Don't warn about missing classes
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
