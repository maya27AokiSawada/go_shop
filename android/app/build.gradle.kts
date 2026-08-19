import java.util.Properties
import java.nio.charset.StandardCharsets

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "net.sumomo_planning.goshopping"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.reader().use { keystoreProperties.load(it) }
    }

    defaultConfig {
        applicationId = "net.sumomo_planning.goshopping"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        missingDimensionStrategy("default", "dev")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    flavorDimensions += "default"
    productFlavors {
        create("prod") {
            dimension = "default"
        }
        create("dev") {
            dimension = "default"
            applicationId = "net.sumomo_planning.goshopping.dev"
            versionNameSuffix = "-dev"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

// Work around intermittent local corruption where Crashlytics generated XML
// becomes a NUL-filled file and breaks Android resource parsing.
val sanitizeCrashlyticsGeneratedRes by tasks.registering {
    doLast {
        val crashlyticsGeneratedDir = layout.buildDirectory.dir("generated/crashlytics/res").get().asFile
        if (!crashlyticsGeneratedDir.exists()) return@doLast

        crashlyticsGeneratedDir
            .walkTopDown()
            .filter { it.isFile && it.name == "com_crashlytics_build_id.xml" }
            .forEach { xmlFile ->
                val bytes = xmlFile.readBytes()
                if (bytes.isEmpty()) return@forEach

                val firstNonNul = bytes.firstOrNull { it.toInt() != 0 }
                if (firstNonNul == null) {
                    xmlFile.delete()
                    return@forEach
                }

                val text = bytes.toString(StandardCharsets.UTF_8)
                if (!text.trimStart().startsWith("<")) {
                    val cleaned = text.replace("\u0000", "")
                    if (cleaned.trimStart().startsWith("<")) {
                        xmlFile.writeText(cleaned, StandardCharsets.UTF_8)
                    } else {
                        xmlFile.delete()
                    }
                }
            }
    }
}

tasks.matching {
    it.name.startsWith("merge") && it.name.endsWith("Resources")
}.configureEach {
    dependsOn(sanitizeCrashlyticsGeneratedRes)
}

// Keep local/public builds reproducible even when Crashlytics credentials are unavailable.
tasks.configureEach {
    if (name.startsWith("uploadCrashlyticsMappingFile")) {
        enabled = false
    }
}
