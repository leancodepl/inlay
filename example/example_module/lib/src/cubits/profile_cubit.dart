import 'package:leancode_add2app/leancode_add2app.dart';

import '../generated/stores.g.dart';

class ProfileCubit extends Add2AppCubit<UserPreferencesStoreSnapshot> {
  ProfileCubit(super.store);

  void updateName(String name) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(displayName: name)));
    }
  }

  void updateEmail(String email) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(email: email)));
    }
  }

  void toggleDarkMode() {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(darkMode: !current.darkMode)));
    }
  }

  void setTheme(AppTheme theme) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(theme: theme)));
    }
  }

  void addTag(String tag) {
    if (state case Add2AppStateReady(data: final current)) {
      if (!current.tags.contains(tag)) {
        emit(Add2AppStateReady(current.copyWith(tags: [...current.tags, tag])));
      }
    }
  }

  void removeTag(String tag) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(
        Add2AppStateReady(
          current.copyWith(tags: current.tags.where((t) => t != tag).toList()),
        ),
      );
    }
  }

  void setNotificationPreferences(NotificationPreferences? prefs) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(notificationPreferences: prefs)));
    }
  }
}
