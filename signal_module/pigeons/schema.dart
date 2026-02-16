import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/navigator/pages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/co/leancode/signal_module/navigator/Pages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'co.leancode.signal_module.navigator',
      errorClassName: 'SignalModuleError',
    ),
    swiftOut: 'ios/Classes/Pages.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'SignalModuleError'),
    dartPackageName: 'signal_module',
  ),
)
// ── Flutter pages (native → Flutter, or Flutter → Flutter) ────────────
/// Page settings for the Sounds & Notifications screen.
//
// add2app: flutter_page
class SoundsNotificationsPage {
  SoundsNotificationsPage({required this.contactId});

  final String contactId;
}

// add2app: flutter_page
class SetWallpaperPage {
  SetWallpaperPage({this.recipientId});

  final String? recipientId;
}

// add2app: flutter_page
class ContactDetailsPage {
  ContactDetailsPage({required this.contactId});

  final String contactId;
}

// ── Native pages (Flutter → native) ──────────────────────────────────

// add2app: native_page
class NativeEditProfilePage {
  NativeEditProfilePage({required this.contactId});

  final String contactId;
}

// add2app: native_page
class NativeMediaViewerPage {
  NativeMediaViewerPage({required this.mediaId, this.mediaType});

  final String mediaId;
  final String? mediaType;
}
