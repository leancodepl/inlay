import 'package:leancode_add2app/leancode_add2app.dart';

@Add2AppStore(key: 'counter')
class CounterStore {
  const CounterStore({this.count = 0, this.lastUpdatedBy = 'flutter'});

  final int count;
  final String lastUpdatedBy;
}

@Add2AppStore(key: 'user_preferences')
class UserPreferencesStore {
  const UserPreferencesStore({
    @Add2AppStoreKey() required this.userId,
    this.displayName = 'User',
    this.email = '',
    this.darkMode = false,
    this.theme = AppTheme.system,
  });

  final String userId;
  final String displayName;
  final String email;
  final bool darkMode;
  final AppTheme theme;
}

enum AppTheme { system, light, dark }
