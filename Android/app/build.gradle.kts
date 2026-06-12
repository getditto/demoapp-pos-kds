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
    alias(libs.plugins.kotlin.plugin.serialization)
}

android {
    namespace = "live.ditto.pos"
    compileSdk = 35

    defaultConfig {
        applicationId = "live.ditto.pos"
        minSdk = 28
        targetSdk = 35
        versionCode = 8
        versionName = "2.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

        // Load Ditto credentials from the shared repo-root .env. Values there
        // are unquoted, so wrap each in quotes for the generated BuildConfig.
        buildConfigField(
            "String",
            "DITTO_DATABASE_ID",
            "\"${dittoEnv("DITTO_DATABASE_ID")}\""
        )

        buildConfigField(
            "String",
            "DITTO_DEVELOPMENT_TOKEN",
            "\"${dittoEnv("DITTO_DEVELOPMENT_TOKEN")}\""
        )

        buildConfigField(
            "String",
            "DITTO_SERVER_URL",
            "\"${dittoEnv("DITTO_SERVER_URL")}\""
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

    // KotlinX Serialization (JSON)
    implementation(libs.kotlinx.serialization.json)
}

kapt {
    correctErrorTypes = true
}

// Reads a value from the shared repo-root .env — the single source of truth
// for Ditto credentials across the iOS and Android apps. Values are unquoted.
fun dittoEnv(key: String): String {
    val envFile = File(rootProject.projectDir.parentFile, ".env")
    if (!envFile.isFile) {
        error("Shared .env not found at ${envFile.absolutePath}. Copy .env.template to .env at the repo root.")
    }
    val properties = Properties()
    InputStreamReader(FileInputStream(envFile), Charsets.UTF_8).use { reader ->
        properties.load(reader)
    }
    return properties.getProperty(key)
        ?: error("Missing \"$key\" in ${envFile.absolutePath}")
}

// Credentials are baked into BuildConfig from the repo-root .env at configuration
// time (see dittoEnv). Declare that file as an input to the BuildConfig-generation
// tasks so editing .env regenerates BuildConfig without needing a clean build.
tasks.matching { it.name.startsWith("generate") && it.name.endsWith("BuildConfig") }
    .configureEach {
        inputs.file(rootProject.file("../.env")).optional().withPropertyName("dotEnv")
    }
