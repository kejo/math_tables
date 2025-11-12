plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import org.gradle.api.GradleException

// Load signing properties from key.properties (optional, not checked in)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { fis ->
        keystoreProperties.load(fis)
    }
}

android {
    namespace = "com.example.math_tables"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.math_tables"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
                // Use configured release signing if key.properties exists.
                // If a release task was requested but key.properties is missing, fail the build to avoid unsigned releases.
                if (keystorePropertiesFile.exists()) {
                    signingConfig = signingConfigs.getByName("release")
                } else {
                    val wantsRelease = gradle.startParameter.taskNames.any { it.lowercase().contains("release") }
                    if (wantsRelease) {
                        throw GradleException("Missing key.properties: create key.properties (see key.properties.example) to sign release builds.")
                    } else {
                        // Non-release tasks (e.g., debug/run) will fall back to debug signing
                        signingConfig = signingConfigs.getByName("debug")
                    }
                }
        }
    }
}

flutter {
    source = "../.."
}
