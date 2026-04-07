/// Annotations for the inlay code generator.
///
/// These annotations mark classes in schema files for code generation.
/// The generator creates serialization code, route handlers, and store wrappers.
library;

/// Marks a class as a Flutter route (native -> Flutter or Flutter -> Flutter).
///
/// The generator creates:
/// - Serialization methods (`encode()`, `decode()`)
/// - Route class extending `FlutterRouteBase` with `toPath()` support
/// - Path-based navigation integration for go_router / auto_route / Navigator 2.0
///
/// Example:
/// ```dart
/// @InlayFlutterRoute('/contact-details/:contactId')
/// class ContactDetailsPage {
///   const ContactDetailsPage({required this.contactId});
///   final String contactId;
/// }
///
/// @InlayFlutterRoute('/products/:id')
/// class ProductDetailPage {
///   const ProductDetailPage({required this.id});
///   final String id;
/// }
/// ```
class InlayFlutterRoute {
  /// Creates an annotation for a Flutter route.
  ///
  /// [path] is the URL path template for this route. Path parameters use
  /// `:fieldName` syntax matching the class fields.
  /// The internal route identifier is auto-derived from the class name
  /// (strip "Page" suffix, camelCase).
  const InlayFlutterRoute(this.path);

  /// URL path template, e.g. '/sounds-notifications/:contactId'.
  final String path;
}

/// Marks a class as a Flutter dialog route (native -> Flutter overlay).
///
/// Like [InlayFlutterRoute] but the native side opens a transparent container
/// so the underlying screen is visible. Flutter code renders the dialog content
/// (barrier, animation, positioning).
///
/// Example:
/// ```dart
/// @InlayFlutterDialog('/confirm-delete/:itemId')
/// class ConfirmDeleteDialog {
///   const ConfirmDeleteDialog({required this.itemId, this.title});
///   final String itemId;
///   final String? title;
/// }
/// ```
class InlayFlutterDialog {
  /// Creates an annotation for a Flutter dialog route.
  ///
  /// [path] is the URL path template for this dialog. Path parameters use
  /// `:fieldName` syntax matching the class fields.
  const InlayFlutterDialog(this.path);

  /// URL path template, e.g. '/confirm-delete/:itemId'.
  final String path;
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
/// @InlayNativeRoute()  // route name defaults to "nativeEditProfile"
/// class NativeEditProfilePage {
///   const NativeEditProfilePage({required this.contactId});
///   final String contactId;
/// }
///
/// @InlayNativeRoute('edit-profile')  // explicit route name
/// class NativeEditProfilePage {
///   const NativeEditProfilePage({required this.contactId});
///   final String contactId;
/// }
/// ```
class InlayNativeRoute {
  /// Creates an annotation for a native route.
  ///
  /// [name] is the route identifier used in navigation. If not provided,
  /// defaults to camelCase of the class name without "Page" suffix.
  const InlayNativeRoute([this.name]);

  /// Optional route name. Defaults to camelCase of class name without "Page" suffix.
  final String? name;
}

/// Marks a class as a typed store over `KeyValueStorage`.
///
/// The generator creates:
/// - A store class with typed getters/setters for each field
/// - A snapshot class with all field values
/// - A reactive stream that emits snapshots on changes
/// - Key generation based on store key and optional `@InlayStoreKey` field
///
/// If a field is annotated with `@InlayStoreKey()`, it becomes the key segment
/// in storage paths and is not stored as a value itself.
///
/// Example:
/// ```dart
/// @InlayStore(key: 'sounds_notifications')
/// class SoundsNotificationsStore {
///   const SoundsNotificationsStore({
///     @InlayStoreKey() required this.contactId,
///     this.mute = false,
///     this.showPreviews = true,
///     this.sound = 'Default',
///   });
///
///   final String contactId;  // key: sounds_notifications/{contactId}/...
///   final bool mute;         // key: sounds_notifications/{contactId}/mute
///   final bool showPreviews; // key: sounds_notifications/{contactId}/showPreviews
///   final String sound;      // key: sounds_notifications/{contactId}/sound
/// }
/// ```
class InlayStore {
  /// Creates an annotation for a typed store.
  ///
  /// [key] is the prefix for all storage keys. If not provided,
  /// defaults to snake_case of the class name without "Store" suffix.
  /// Example: `SoundsNotificationsStore` -> `"sounds_notifications"`
  const InlayStore({this.key});

  /// Optional key prefix for storage keys.
  /// Defaults to snake_case of class name without "Store" suffix.
  final String? key;
}

/// Marks a single field inside `@InlayStore` class as the store key.
///
/// Only one field per store may be annotated. Supported key field types:
/// - `String`
/// - `int`
/// - enum
class InlayStoreKey {
  const InlayStoreKey();
}

// Note: no convenience constant for InlayFlutterRoute since `path` is required.

/// Convenience constant for `@InlayNativeRoute()` annotation.
const inlayNativeRoute = InlayNativeRoute();

/// Convenience constant for `@InlayStore()` annotation.
const inlayStore = InlayStore();

/// Convenience constant for `@InlayStoreKey()` annotation.
const inlayStoreKey = InlayStoreKey();
