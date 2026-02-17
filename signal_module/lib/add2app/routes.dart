import 'package:leancode_add2app/leancode_add2app.dart';

// ── Flutter Routes ─────────────────────────────────────────────────────────
//
// Routes for navigating to Flutter screens from native or other Flutter screens.

/// Page settings for the Sounds & Notifications screen.
@Add2AppFlutterRoute()
class SoundsNotificationsPage {
  const SoundsNotificationsPage({required this.contactId});

  final String contactId;
}

/// Page settings for the Set Wallpaper screen.
@Add2AppFlutterRoute()
class SetWallpaperPage {
  const SetWallpaperPage({this.recipientId});

  final String? recipientId;
}

/// Page settings for the Contact Details screen.
@Add2AppFlutterRoute()
class ContactDetailsPage {
  const ContactDetailsPage({required this.contactId});

  final String contactId;
}

// ── Native Routes ──────────────────────────────────────────────────────────
//
// Routes for navigating to native screens from Flutter.

/// Page settings for the native Edit Profile screen.
@Add2AppNativeRoute()
class NativeEditProfilePage {
  const NativeEditProfilePage({required this.contactId});

  final String contactId;
}

/// Page settings for the native Media Viewer screen.
@Add2AppNativeRoute()
class NativeMediaViewerPage {
  const NativeMediaViewerPage({required this.mediaId, this.mediaType});

  final String mediaId;
  final String? mediaType;
}
