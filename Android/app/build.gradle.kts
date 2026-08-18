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
    compileSdk = 36

    defaultConfig {
        applicationId = "live.ditto.pos"
        minSdk = 28
        targetSdk = 36
        versionCode = 9
        versionName = "1"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
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

// Bake the Ditto credentials into BuildConfig from the shared repo-root .env
// (see dittoEnv). Wired through androidComponents.onVariants with a lazy
// provider so the file is read only when BuildConfig is actually generated — a
// fresh clone can still run non-build tasks (./gradlew tasks, IDE sync) with no
// .env present. Values in .env are unquoted, so wrap each in quotes for the
// generated Java string literal.
androidComponents {
    onVariants { variant ->
        listOf(
            "DITTO_DATABASE_ID",
            "DITTO_DEVELOPMENT_TOKEN",
            "DITTO_SERVER_URL"
        ).forEach { key ->
            variant.buildConfigFields?.put(
                key,
                providers.provider {
                    com.android.build.api.variant.BuildConfigField(
                        "String",
                        "\"${dittoEnv(key)}\"",
                        null
                    )
                }
            )
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
    return properties.getProperty(key)?.ifBlank { null }
        ?: error(
            "Missing or blank \"$key\" in ${envFile.absolutePath}. " +
                "Fill in every value from .env.template before building."
        )
}
