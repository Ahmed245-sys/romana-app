plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.romana.delivery"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = "romana"
            keyPassword = "romana123"
            storeFile = file("romana-key.jks")
            storePassword = "romana123"
        }
    }

    defaultConfig {
        applicationId = "com.romana.delivery"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    constraints {
        implementation("com.google.protobuf:protobuf-javalite:3.22.3") {
            because("resolves duplicate protobuf classes")
        }
    }
    implementation("com.google.protobuf:protobuf-javalite:3.22.3") {
        exclude(group = "com.google.protobuf", module = "protobuf-java")
    }
}