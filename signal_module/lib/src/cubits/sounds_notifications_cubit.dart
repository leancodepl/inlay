import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/generated/stores.g.dart';

class SoundsNotificationsCubit
    extends Add2AppCubit<SoundsNotificationsStoreSnapshot> {
  SoundsNotificationsCubit(super.store);

  void toggleMute() {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(mute: !current.mute)));
    }
  }

  void setShowPreviews({required bool value}) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(showPreviews: value)));
    }
  }

  void changeSound(String sound) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(sound: sound)));
    }
  }

  void changeVibration(VibrationLevel level) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(vibration: level)));
    }
  }

  void changeBehavior(NotificationBehavior behavior) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(behavior: behavior)));
    }
  }
}
