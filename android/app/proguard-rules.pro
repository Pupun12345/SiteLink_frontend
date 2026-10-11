# ═══════════════════════════════════════════════════════════════════
#  PROGUARD / R8 — release build ke liye
# ═══════════════════════════════════════════════════════════════════
# Flutter khud apne engine ke rules inject karta hai, isliye yahan sirf
# wo plugins likhe hain jo reflection use karte hain — R8 unke classes
# ko "unused" samajh kar hata deta hai aur app release me crash hoti hai
# (debug me sab theek dikhta hai, isliye ye pakadna mushkil hota hai).

# ── Razorpay ───────────────────────────────────────────────────────
# Checkout Activity reflection se khulti hai; annotations bhi chahiye.
-keep class com.razorpay.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn com.razorpay.**
# Razorpay ke andar ye optional dependencies hain jo hum use nahi karte.
-dontwarn proguard.annotation.**
-keep class proguard.annotation.** { *; }

# ── Firebase / Google Play Services ────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Kotlin coroutines / metadata ───────────────────────────────────
-keepclassmembers class kotlinx.** { volatile <fields>; }
-dontwarn kotlinx.**

# Line numbers rakho taaki release crash ke stack trace padh sakein.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
