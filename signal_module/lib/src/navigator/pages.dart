import 'add2app_navigator.dart';

// ── Flutter pages (native → Flutter, or Flutter → Flutter) ────────────

/// Page settings for the Sounds & Notifications screen.
///
/// ```dart
/// Add2AppNavigator.instance.push(
///   SoundsNotificationsPage(contactId: '42'),
/// );
/// ```
class SoundsNotificationsPage extends Add2AppPage {
  const SoundsNotificationsPage({required this.contactId});

  final String contactId;

  @override
  String get routeId => 'soundsNotifications';

  @override
  Map<String, String> get params => {'contactId': contactId};
}

/// Page settings for the Set Wallpaper screen.
class SetWallpaperPage extends Add2AppPage {
  const SetWallpaperPage({this.recipientId});

  final String? recipientId;

  @override
  String get routeId => 'setWallpaper';

  @override
  Map<String, String> get params => {
    ...?recipientId != null ? {'recipientId': recipientId!} : null,
  };
}

/// Page settings for the Contact Details screen.
class ContactDetailsPage extends Add2AppPage {
  const ContactDetailsPage({required this.contactId});

  final String contactId;

  @override
  String get routeId => 'contactDetails';

  @override
  Map<String, String> get params => {'contactId': contactId};
}

// ── Native pages (Flutter → native) ──────────────────────────────────

/// Opens the native profile editor Activity/ViewController.
///
/// The native side must register a handler for this route:
///
/// **Android:**
/// ```kotlin
/// Add2AppNavigator.registerNativeRoute("nativeEditProfile") { context, params ->
///     val intent = Intent(context, EditProfileActivity::class.java).apply {
///         putExtra("contactId", params?.get("contactId"))
///     }
///     context.startActivity(intent)
/// }
/// ```
///
/// **iOS:**
/// ```swift
/// Add2AppNavigator.shared.registerNativeRoute("nativeEditProfile") { vc, params in
///     let editor = EditProfileViewController()
///     editor.contactId = params?["contactId"]
///     vc.navigationController?.pushViewController(editor, animated: true)
/// }
/// ```
///
/// **Flutter:**
/// ```dart
/// Add2AppNavigator.instance.pushNativeRoute(
///   NativeEditProfilePage(contactId: '42'),
/// );
/// ```
class NativeEditProfilePage extends Add2AppPage {
  const NativeEditProfilePage({required this.contactId});

  final String contactId;

  @override
  String get routeId => 'nativeEditProfile';

  @override
  Map<String, String> get params => {'contactId': contactId};
}

/// Opens the native media viewer Activity/ViewController.
///
/// **Flutter:**
/// ```dart
/// Add2AppNavigator.instance.pushNativeRoute(
///   NativeMediaViewerPage(mediaId: '123', mediaType: 'photo'),
/// );
/// ```
class NativeMediaViewerPage extends Add2AppPage {
  const NativeMediaViewerPage({required this.mediaId, this.mediaType = 'photo'});

  final String mediaId;
  final String mediaType;

  @override
  String get routeId => 'nativeMediaViewer';

  @override
  Map<String, String> get params => {
    'mediaId': mediaId,
    'mediaType': mediaType,
  };
}
