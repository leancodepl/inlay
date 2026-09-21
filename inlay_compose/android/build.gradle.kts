group = "co.leancode.inlay.compose"
version = "0.2.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.9.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
        classpath("org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.2.20")
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
apply(plugin = "org.jetbrains.kotlin.plugin.compose")

val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)

android.apply {
    namespace = "co.leancode.inlay.compose"
    compileSdk = 36

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

project.dependencies.apply {
    add("implementation", project(":inlay"))
    add("implementation", "androidx.fragment:fragment-ktx:1.8.3")
    add("implementation", "androidx.activity:activity-compose:1.9.2")
    add("implementation", platform("androidx.compose:compose-bom:2024.09.02"))
    add("implementation", "androidx.compose.runtime:runtime")
    add("implementation", "androidx.compose.ui:ui")
    add("implementation", "androidx.compose.foundation:foundation")
}
