/// Annotations for the leancode_add2app code generator.
///
/// These annotations mark classes in schema files for code generation.
/// The generator creates serialization code, route handlers, and store wrappers.
library;

/// Marks a class as a Flutter route (native -> Flutter or Flutter -> Flutter).
///
/// The generator creates:
/// - Serialization methods (`encode()`, `decode()`)
/// - Route class extending `Add2AppFlutterRoute`
/// - Handler method in `FlutterRouteHandler`
///
/// Example:
/// ```dart
/// @Add2AppFlutterRoute()  // route name defaults to "contactDetails"
/// class ContactDetailsPage {
///   const ContactDetailsPage({required this.contactId});
///   final String contactId;
/// }
///
/// @Add2AppFlutterRoute('sounds-notifications')  // explicit route name
/// class SoundsNotificationsPage {
///   const SoundsNotificationsPage({required this.contactId});
///   final String contactId;
/// }
/// ```
class Add2AppFlutterRoute {
  /// Creates an annotation for a Flutter route.
  ///
  /// [name] is the route identifier used in navigation. If not provided,
  /// defaults to camelCase of the class name without "Page" suffix.
  /// Example: `ContactDetailsPage` -> `"contactDetails"`
  const Add2AppFlutterRoute([this.name]);

  /// Optional route name. Defaults to camelCase of class name without "Page" suffix.
  final String? name;
}

/// Marks a class as a native route (Flutter -> native).
///
/// The generator creates:
/// - Serialization methods (`encode()`, `decode()`, `toList()`, `fromList()`)
/// - `toNativeRoute()` method for navigation
/// - Handler method in `NativeRouteHandler` (Kotlin/Swift)
///
/// Example:
/// ```dart
/// @Add2AppNativeRoute()  // route name defaults to "nativeEditProfile"
/// class NativeEditProfilePage {
///   const NativeEditProfilePage({required this.contactId});
///   final String contactId;
/// }
///
/// @Add2AppNativeRoute('edit-profile')  // explicit route name
/// class NativeEditProfilePage {
///   const NativeEditProfilePage({required this.contactId});
///   final String contactId;
/// }
/// ```
class Add2AppNativeRoute {
  /// Creates an annotation for a native route.
  ///
  /// [name] is the route identifier used in navigation. If not provided,
  /// defaults to camelCase of the class name without "Page" suffix.
  const Add2AppNativeRoute([this.name]);

  /// Optional route name. Defaults to camelCase of class name without "Page" suffix.
  final String? name;
}

/// Marks a class as a typed store over `KeyValueStorage`.
///
/// The generator creates:
/// - A store class with typed getters/setters for each field
/// - A snapshot class with all field values
/// - A reactive stream that emits snapshots on changes
/// - Key generation based on store key and scoping fields
///
/// Scoping fields are constructor parameters marked as `required` without defaults.
/// They are used in the storage key prefix but not stored as values themselves.
///
/// Example:
/// ```dart
/// @Add2AppStore(key: 'sounds_notifications')
/// class SoundsNotificationsStore {
///   const SoundsNotificationsStore({
///     required this.contactId,  // scoping field - used in key prefix
///     this.mute = false,
///     this.showPreviews = true,
///     this.sound = 'Default',
///   });
///
///   final String contactId;  // scope: sounds_notifications/{contactId}/...
///   final bool mute;         // key: sounds_notifications/{contactId}/mute
///   final bool showPreviews; // key: sounds_notifications/{contactId}/showPreviews
///   final String sound;      // key: sounds_notifications/{contactId}/sound
/// }
/// ```
class Add2AppStore {
  /// Creates an annotation for a typed store.
  ///
  /// [key] is the prefix for all storage keys. If not provided,
  /// defaults to snake_case of the class name without "Store" suffix.
  /// Example: `SoundsNotificationsStore` -> `"sounds_notifications"`
  const Add2AppStore({this.key});

  /// Optional key prefix for storage keys.
  /// Defaults to snake_case of class name without "Store" suffix.
  final String? key;
}

/// Convenience constant for `@Add2AppFlutterRoute()` annotation.
const add2AppFlutterRoute = Add2AppFlutterRoute();

/// Convenience constant for `@Add2AppNativeRoute()` annotation.
const add2AppNativeRoute = Add2AppNativeRoute();

/// Convenience constant for `@Add2AppStore()` annotation.
const add2AppStore = Add2AppStore();
