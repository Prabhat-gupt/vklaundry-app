# Disable all obfuscation for Razorpay
-keep class com.razorpay.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepclassmembers class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.AnalyticsUtil { *; }

# Keep all methods in AnalyticsUtil
-keep class com.razorpay.AnalyticsUtil { 
    *** logFunctionEntry(...);
    *** logFunctionExit(...);
    *;
}

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keepclassmembers class com.google.firebase.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }

# Keep reflection safe
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-dontwarn com.razorpay.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
