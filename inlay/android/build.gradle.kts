group = "co.leancode.inlay"
version = "0.2.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.9.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply(plugin = "com.android.library")
apply(plugin = "kotlin-android")

val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)

android.apply {
    namespace = "co.leancode.inlay"
    compileSdk = 36

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        // Storage unit tests only touch the data layer; Handler/Looper
        // notification dispatch becomes a no-op instead of throwing.
        unitTests.isReturnDefaultValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

project.dependencies.apply {
    add("implementation", "androidx.fragment:fragment-ktx:1.8.3")
    add("testImplementation", "junit:junit:4.13.2")
}
