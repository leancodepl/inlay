import 'package:inlay/inlay.dart';

import '../generated/stores.g.dart';

class ProfileCubit extends InlayCubit<UserPreferencesStoreSnapshot> {
  ProfileCubit(super.store);

  void updateName(String name) {
    if (state case InlayStateReady(data: final current)) {
      emit(InlayStateReady(current.copyWith(displayName: name)));
    }
  }

  void updateEmail(String email) {
    if (state case InlayStateReady(data: final current)) {
      emit(InlayStateReady(current.copyWith(email: email)));
    }
  }

  void toggleDarkMode() {
    if (state case InlayStateReady(data: final current)) {
      emit(InlayStateReady(current.copyWith(darkMode: !current.darkMode)));
    }
  }

  void setTheme(AppTheme theme) {
    if (state case InlayStateReady(data: final current)) {
      emit(InlayStateReady(current.copyWith(theme: theme)));
    }
  }

  void addTag(String tag) {
    if (state case InlayStateReady(data: final current)) {
      if (!current.tags.contains(tag)) {
        emit(InlayStateReady(current.copyWith(tags: [...current.tags, tag])));
      }
    }
  }

  void removeTag(String tag) {
    if (state case InlayStateReady(data: final current)) {
      emit(
        InlayStateReady(
          current.copyWith(tags: current.tags.where((t) => t != tag).toList()),
        ),
      );
    }
  }

  void setNotificationPreferences(NotificationPreferences? prefs) {
    if (state case InlayStateReady(data: final current)) {
      emit(InlayStateReady(current.copyWith(notificationPreferences: prefs)));
    }
  }
}
