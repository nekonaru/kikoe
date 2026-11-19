plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.nekonaru.kikoe"
    // receive_sharing_intent is compiled against Android SDK 37, so the app must be too.
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.nekonaru.kikoe"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Release keystore path and credentials come from the environment,
            // never from the repo. When they are absent (local dev, PRs from
            // forks), the release build falls back to the debug key.
            val keystoreFile = System.getenv("KIKOE_KEYSTORE_FILE")
            if (!keystoreFile.isNullOrEmpty()) {
                storeFile = file(keystoreFile)
                storePassword = System.getenv("KIKOE_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KIKOE_KEY_ALIAS")
                keyPassword = System.getenv("KIKOE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val keystoreFile = System.getenv("KIKOE_KEYSTORE_FILE")
            signingConfig = if (!keystoreFile.isNullOrEmpty()) {
                signingConfigs.getByName("release")
            } else {
                // Debug key only when no release keystore is configured.
                signingConfigs.getByName("debug")
            }
        }
    }
}



flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications on older Android versions.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
