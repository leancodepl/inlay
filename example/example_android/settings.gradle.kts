pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
  val storageUrl: String = System.getenv("FLUTTER_STORAGE_BASE_URL")
    ?: "https://storage.googleapis.com"
  repositories {
    google()
    mavenCentral()
    maven("$storageUrl/download.flutter.io")
  }
}

include(":app")
include(":example_module")
apply(from = File(settingsDir.parentFile, "example_module/.android/include_flutter.groovy"))
project(":example_module").projectDir = File(settingsDir.parentFile, "example_module")

rootProject.name = "Example-Android"
