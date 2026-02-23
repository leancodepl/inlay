import 'package:leancode_add2app/leancode_add2app.dart';
// ── Stores ─────────────────────────────────────────────────────────────────
//
// Typed wrappers over KeyValueStorage for app-specific data.

/// Store for sound and notification settings per contact.
@Add2AppStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    @Add2AppStoreKey() required this.contactId,
    this.mute = false,
    this.showPreviews = true,
    this.sound = 'Default',
    this.vibration = VibrationLevel.normal,
    this.behavior = NotificationBehavior.defaultBehavior,
  });

  /// Contact ID - used as key segment in storage path.
  final String contactId;

  /// Whether notifications are muted for this contact.
  final bool mute;

  /// Whether to show notification previews.
  final bool showPreviews;

  /// Sound setting for this contact.
  final String sound;

  /// Vibration setting for this contact.
  final VibrationLevel vibration;

  /// Notification behavior preset.
  final NotificationBehavior behavior;
}

/// Store for user preferences (global, not scoped).
@Add2AppStore(key: 'user_preferences')
class UserPreferencesStore {
  const UserPreferencesStore({
    this.darkMode = false,
    this.locale,
    this.theme = AppTheme.system,
  });

  /// Whether dark mode is enabled.
  final bool darkMode;

  /// User's preferred locale (null = system default).
  final String? locale;

  /// App theme preference.
  final AppTheme theme;
}

/// Store keyed by integer thread ID.
@Add2AppStore(key: 'thread_preferences')
class ThreadPreferencesStore {
  const ThreadPreferencesStore({
    @Add2AppStoreKey() required this.threadId,
    this.unreadCount = 0,
    this.fontScale = 1.0,
    this.behavior = NotificationBehavior.defaultBehavior,
  });

  final int threadId;
  final int unreadCount;
  final double fontScale;
  final NotificationBehavior behavior;
}

/// Store keyed by enum value.
@Add2AppStore(key: 'category_preferences')
class CategoryPreferencesStore {
  const CategoryPreferencesStore({
    @Add2AppStoreKey() required this.category,
    this.pinned = false,
    this.label = 'General',
  });

  final ConversationCategory category;
  final bool pinned;
  final String label;
}

enum NotificationBehavior { defaultBehavior, mentionsOnly, muted }

enum AppTheme { system, light, dark }

enum VibrationLevel {
  off(0),
  normal(1),
  intense(2);

  const VibrationLevel(this.strength);

  final int strength;
}

enum ConversationCategory {
  direct('direct'),
  group('group'),
  archived('archived');

  const ConversationCategory(this.code);

  final String code;
}
