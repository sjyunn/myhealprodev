plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bluetooth_headset_app"
    compileSdk = 36  // ← 34에서 35로 업그레이드
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // ← 11에서 17로 업그레이드
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()  // ← 11에서 17로 업그레이드
    }

    defaultConfig {
        applicationId = "com.example.bluetooth_headset_app"
        minSdk = 28  // Health Connect 요구사항
        targetSdk = 36  // ← 34에서 35로 업그레이드
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}