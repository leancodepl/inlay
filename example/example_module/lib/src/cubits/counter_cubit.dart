import 'package:inlay/inlay.dart';

import '../generated/stores.g.dart';

class CounterCubit extends InlayCubit<CounterStoreSnapshot> {
  CounterCubit(super.store);

  void increment() {
    if (state case InlayStateReady(data: final current)) {
      emit(
        InlayStateReady(
          current.copyWith(count: current.count + 1, lastUpdatedBy: 'flutter'),
        ),
      );
    }
  }

  void decrement() {
    if (state case InlayStateReady(data: final current)) {
      emit(
        InlayStateReady(
          current.copyWith(count: current.count - 1, lastUpdatedBy: 'flutter'),
        ),
      );
    }
  }

  void reset() {
    if (state case InlayStateReady(data: final current)) {
      emit(
        InlayStateReady(current.copyWith(count: 0, lastUpdatedBy: 'flutter')),
      );
    }
  }
}
