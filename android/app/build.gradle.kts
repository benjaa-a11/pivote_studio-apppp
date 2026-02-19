plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.pivote_studio"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.pivote_studio"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // ⚠️ Para producción REAL cambiar por signingConfigs.release
            signingConfig = signingConfigs.getByName("debug")

            // Optimización real
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        debug {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

    /* =========================
       FIREBASE (solo lo necesario)
       ========================= */
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-messaging")
    
    /* =========================
       GOOGLE PLAY SERVICES
       ========================= */
    implementation("com.google.android.gms:play-services-auth:21.0.0")

    /* =========================
       ANDROIDX BÁSICO
       ========================= */
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.multidex:multidex:2.0.1")
    
    /* =========================
       DESUGARING (requerido por flutter_local_notifications)
       ========================= */
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
