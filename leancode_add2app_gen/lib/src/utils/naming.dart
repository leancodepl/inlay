// Naming utilities for code generation.

/// Converts a PascalCase or camelCase string to snake_case.
///
/// - `SoundsNotifications` → `sounds_notifications`
/// - `contactId` → `contact_id`
String toSnakeCase(String input) {
  if (input.isEmpty) return input;

  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char.toUpperCase() == char && char.toLowerCase() != char) {
      // It's an uppercase letter.
      if (i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

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

/// Derives a store key from a store class name.
///
/// Strips the `Store` suffix and converts to snake_case.
/// - `SoundsNotificationsStore` → `sounds_notifications`
/// - `UserPreferencesStore` → `user_preferences`
String storeKeyFromClassName(String className) {
  var name = className;
  if (name.endsWith('Store')) {
    name = name.substring(0, name.length - 5);
  }
  return toSnakeCase(name);
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
