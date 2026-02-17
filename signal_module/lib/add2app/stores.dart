import 'package:leancode_add2app/leancode_add2app.dart';
// ── Stores ─────────────────────────────────────────────────────────────────
//
// Typed wrappers over KeyValueStorage for app-specific data.

/// Store for sound and notification settings per contact.
@Add2AppStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    required this.contactId, // Scoping field
    this.mute = false,
    this.showPreviews = true,
    this.sound = 'Default',
    this.vibration = 'Default',
  });

  /// Contact ID - used as scope in storage key.
  final String contactId;

  /// Whether notifications are muted for this contact.
  final bool mute;

  /// Whether to show notification previews.
  final bool showPreviews;

  /// Sound setting for this contact.
  final String sound;

  /// Vibration setting for this contact.
  final String vibration;
}

/// Store for user preferences (global, not scoped).
@Add2AppStore(key: 'user_preferences')
class UserPreferencesStore {
  const UserPreferencesStore({this.darkMode = false, this.locale});

  /// Whether dark mode is enabled.
  final bool darkMode;

  /// User's preferred locale (null = system default).
  final String? locale;
}
