import java.io.FileInputStream
import java.io.InputStreamReader
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.jetbrains.kotlin.android)
    alias(libs.plugins.google.dagger.hilt.android)
    alias(libs.plugins.ktlint)
    alias(libs.plugins.jetbrains.kotlin.kapt)
    alias(libs.plugins.kotlin.plugin.compose)
}

android {
    namespace = "live.ditto.pos"
    compileSdk = 35

    defaultConfig {
        applicationId = "live.ditto.pos"
        minSdk = 28
        targetSdk = 34
        versionCode = 5
        versionName = "5"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

        // Load Ditto API keys
        buildConfigField(
            "String",
            "DITTO_ONLINE_PLAYGROUND_APP_ID",
            getLocalProperty("dittoOnlinePlaygroundAppId")
        )

        buildConfigField(
            "String",
            "DITTO_ONLINE_PLAYGROUND_TOKEN",
            getLocalProperty("dittoOnlinePlaygroundToken")
        )

        buildConfigField(
            "String",
            "DITTO_WEBSOCKET_URL",
            getLocalProperty("dittoWebsocketURL")
        )
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.10"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(project(":ditto-wrapper"))
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)

    // Hilt
    implementation(libs.hilt.android)
    kapt(libs.hilt.compiler)
    implementation(libs.androidx.hilt.navigation.compose)

    // Hilt For instrumentation tests
    androidTestImplementation(libs.hilt.android.testing)
    androidTestAnnotationProcessor(libs.hilt.compiler)

    // Hilt For local unit tests
    testImplementation(libs.hilt.android.testing)
    testAnnotationProcessor(libs.hilt.compiler)

    // Ditto
    implementation(libs.ditto)

    // Jetpack navigation
    implementation(libs.androidx.navigation.compose)

    // Extended material icons
    // todo: remove and just grab individual icons
    implementation(libs.androidx.material.icons.extended.android)

    implementation(libs.ditto.tools)

    // Jetpack Datastore
    implementation(libs.androidx.datastore.preferences)

    // KotlinX DateTime
    implementation(libs.kotlinx.datetime)
}

kapt {
    correctErrorTypes = true
}

fun getLocalProperty(key: String, file: String = "local.properties"): String {
    val properties = Properties()
    val localProperties = File(file)
    if (localProperties.isFile) {
        InputStreamReader(FileInputStream(localProperties), Charsets.UTF_8).use { reader ->
            properties.load(reader)
        }
    } else {
        error("File not found")
    }

    return properties.getProperty(key)
}
