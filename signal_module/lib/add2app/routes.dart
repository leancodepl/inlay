import 'package:leancode_add2app/leancode_add2app.dart';

// ── Flutter Routes ─────────────────────────────────────────────────────────
//
// Routes for navigating to Flutter screens from native or other Flutter screens.

/// Page settings for the Sounds & Notifications screen.
@Add2AppFlutterRoute('/sounds-notifications/:contactId')
class SoundsNotificationsPage {
  const SoundsNotificationsPage({
    required this.contactId,
    this.preferences,
    this.presets,
    this.fallbackChannel,
  });

  final String contactId;
  final NotificationPreferences? preferences;
  final List<NotificationPreset>? presets;
  final DeliveryChannel? fallbackChannel;
}

/// Page settings for the Set Wallpaper screen.
@Add2AppFlutterRoute('/set-wallpaper/:recipientId')
class SetWallpaperPage {
  const SetWallpaperPage({this.recipientId, this.options, this.preferredKind});

  final String? recipientId;
  final List<WallpaperOption>? options;
  final WallpaperKind? preferredKind;
}

/// Page settings for the Contact Details screen.
@Add2AppFlutterRoute('/contact-details/:contactId')
class ContactDetailsPage {
  const ContactDetailsPage({
    required this.contactId,
    this.badges,
    this.preferredSound,
  });

  final String contactId;
  final List<ContactBadge>? badges;
  final NotificationSound? preferredSound;
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

class NotificationPreset {
  const NotificationPreset({required this.name, required this.preferences});

  final String name;
  final NotificationPreferences preferences;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.sound,
    required this.channels,
    this.quietHours,
  });

  final NotificationSound sound;
  final List<DeliveryChannel> channels;
  final QuietHours? quietHours;
}

class QuietHours {
  const QuietHours({required this.fromHour, required this.toHour});

  final int fromHour;
  final int toHour;
}

class WallpaperOption {
  const WallpaperOption({required this.assetName, required this.kind});

  final String assetName;
  final WallpaperKind kind;
}

class ContactBadge {
  const ContactBadge({required this.label, required this.priority});

  final String label;
  final BadgePriority priority;
}

enum NotificationSound { defaultSound, chime, pop }

enum BadgePriority { low, medium, high }

enum DeliveryChannel {
  push('push', true),
  sms('sms', false),
  email('email', true);

  const DeliveryChannel(this.code, this.supportsPreview);

  final String code;
  final bool supportsPreview;

  bool get isFallback => !supportsPreview;
}

enum WallpaperKind {
  staticImage('static'),
  live('live');

  const WallpaperKind(this.code);

  final String code;
}
