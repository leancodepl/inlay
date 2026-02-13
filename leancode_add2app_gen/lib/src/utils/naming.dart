// Naming utilities for code generation.

/// Derives a routeId from a page class name.
///
/// Strips the `Page` suffix and lowercases the first character.
/// - `NativeEditProfilePage` → `nativeEditProfile`
/// - `NativeMediaViewerPage` → `nativeMediaViewer`
String routeIdFromClassName(String className) {
  var name = className;
  if (name.endsWith('Page')) {
    name = name.substring(0, name.length - 4);
  }
  if (name.isEmpty) return name;
  return name[0].toLowerCase() + name.substring(1);
}

/// Derives a Kotlin/Swift handler method name from a page class name.
///
/// Strips the `Page` suffix and prepends `on`.
/// - `NativeEditProfilePage` → `onNativeEditProfile`
/// - `NativeMediaViewerPage` → `onNativeMediaViewer`
String methodNameFromClassName(String className) {
  var name = className;
  if (name.endsWith('Page')) {
    name = name.substring(0, name.length - 4);
  }
  return 'on$name';
}

/// Derives a Kotlin data class name from a page class name.
///
/// Strips the `Page` suffix and appends `Route`.
/// - `NativeEditProfilePage` → `NativeEditProfileRoute`
/// - `NativeMediaViewerPage` → `NativeMediaViewerRoute`
String routeClassFromClassName(String className) {
  var name = className;
  if (name.endsWith('Page')) {
    name = name.substring(0, name.length - 4);
  }
  return '${name}Route';
}
