import 'package:inlay/inlay.dart';

@InlayStore(key: 'counter')
class CounterStore {
  const CounterStore({this.count = 0, this.lastUpdatedBy = 'flutter'});

  final int count;
  final String lastUpdatedBy;
}

@InlayStore(key: 'user_preferences')
class UserPreferencesStore {
  const UserPreferencesStore({
    @InlayStoreKey() required this.userId,
    this.displayName = 'User',
    this.email = '',
    this.darkMode = false,
    this.theme = AppTheme.system,
    this.tags = const [],
    this.notificationPreferences,
  });

  final String userId;
  final String displayName;
  final String email;
  final bool darkMode;
  final AppTheme theme;
  final List<String> tags;
  final NotificationPreferences? notificationPreferences;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.sound = 'Default',
    this.vibration = true,
  });

  final String sound;
  final bool vibration;
}

enum AppTheme { system, light, dark }
