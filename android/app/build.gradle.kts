import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── Release signing ────────────────────────────────────────────────
// Play Store debug-signed build reject kar deta hai, isliye release ke
// liye apni upload key chahiye.
//
// Credentials `android/key.properties` me hain — wo file aur .jks dono
// gitignored hain, jaan-boojh kar: keystore repo me chala jaaye to koi
// bhi aapke naam se update publish kar sakta hai.
//
// File na ho (jaise CI ya kisi doosre machine par) to release build
// debug key par gir jaati hai — tab bhi local testing chalti rahe.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sitelink.sitelink"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications ko chahiye (Java 8+ APIs on older Android)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sitelink.sitelink"
        // video_compress ko minSdk 24 chahiye
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // storeFile path key.properties ke folder (android/) se
                // relative hai, app/ se nahi.
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Code shrink + resource shrink — AAB ka size kam karta hai.
            // Flutter apne ProGuard rules deta hai, isliye extra config
            // ki zaroorat nahi.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))
    // firebase-analytics jaan-boojh kar nahi hai: app me kahin Analytics
    // use hi nahi hoti (na pubspec me firebase_analytics package hai, na
    // Dart me koi call). Wo sirf apni library manifest se AD_ID aur
    // ACCESS_ADSERVICES_* permissions merge kar rahi thi, jiski wajah se
    // Play Console app ko "advertising ID use karta hai" maan leta tha.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}