import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = file(
    "${System.getProperty("user.home")}/os/lianleme-signing.properties",
)
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
}

android {
    namespace = "com.yihang.llme"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    flavorDimensions += "environment"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yihang.llme"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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
            if (signingPropertiesFile.exists()) {
                storeFile = file(
                    requireNotNull(signingProperties.getProperty("storeFile")),
                )
                storePassword = requireNotNull(
                    signingProperties.getProperty("storePassword"),
                )
                keyAlias = requireNotNull(signingProperties.getProperty("keyAlias"))
                keyPassword = requireNotNull(
                    signingProperties.getProperty("keyPassword"),
                )
                storeType = requireNotNull(signingProperties.getProperty("storeType"))
            }
        }
    }

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.yihang.dev.llme"
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.yihang.llme"
            signingConfig = signingConfigs.getByName("release")
        }
    }

    buildTypes {
        release {
            // Only prodRelease is configured with the permanent release key.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core:1.16.0")
}
