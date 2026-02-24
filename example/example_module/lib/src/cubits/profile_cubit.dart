import 'package:leancode_add2app/leancode_add2app.dart';

import '../generated/routes.g.dart';
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
}
