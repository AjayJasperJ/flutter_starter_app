import java.util.Properties
import java.io.FileInputStream


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_starter_app"
    compileSdk = 36
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_starter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // signingConfigs {
    //     create("release") {
    //         val keystorePropertiesFile = rootProject.file("../android/credentials/key.properties")
    //         val keystoreProperties = Properties().apply {
    //             load(FileInputStream(keystorePropertiesFile))
    //         }
    //         storeFile = file(keystoreProperties["storeFile"] as String)
    //         storePassword = keystoreProperties["storePassword"] as String
    //         keyAlias = keystoreProperties["keyAlias"] as String
    //         keyPassword = keystoreProperties["keyPassword"] as String
    //     }
    // }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.play:review:2.0.1") 
    implementation("com.google.android.play:asset-delivery:2.2.2")
}