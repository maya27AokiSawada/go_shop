import java.nio.charset.StandardCharsets
import java.util.Properties

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
    // google_mobile_ads pulls in play-services-ads-api:25.3.0, which pins
    // androidx.work:work-runtime:2.7.0. That version crashes building its
    // Room WorkDatabase on Android 15/16 (RuntimeException: Failed to create
    // an instance of androidx.work.impl.WorkDatabase), killing the app on
    // launch. Force a current work-runtime so Gradle's conflict resolution
    // picks it over the stale transitive pin.
    implementation("androidx.work:work-runtime:2.12.0")
}

android {
    namespace = "net.sumomo_planning.goshopping"
    // package_info_plus requires compileSdk 36+; override the Flutter-provided
    // default (34) until the bundled Flutter SDK raises it.
    compileSdk = 36
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

    // AdMob App ID comes from the untracked project-root .env (same file the
    // Dart side reads via flutter_dotenv). Without it, fall back to Google's
    // sample App ID: the Mobile Ads SDK crashes on launch if the manifest
    // meta-data is missing or empty.
    val dotEnvFile = rootProject.file("../.env")
    val dotEnv = Properties()
    if (dotEnvFile.exists()) {
        dotEnvFile.reader().use { dotEnv.load(it) }
    }
    val admobAppId = dotEnv.getProperty("ADMOB_APP_ID")?.trim().orEmpty()
        .ifEmpty { "ca-app-pub-3940256099942544~3347511713" }

    defaultConfig {
        manifestPlaceholders["admobAppId"] = admobAppId
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
