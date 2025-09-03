# Keep annotations used by Razorpay
-keep class proguard.annotation.** { *; }

# Keep Razorpay SDK classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
