import 'package:leancode_add2app/leancode_add2app.dart';

import '../generated/stores.g.dart';

class CounterCubit extends Add2AppCubit<CounterStoreSnapshot> {
  CounterCubit(super.store);

  void increment() {
    if (state case Add2AppStateReady(data: final current)) {
      emit(
        Add2AppStateReady(
          current.copyWith(count: current.count + 1, lastUpdatedBy: 'flutter'),
        ),
      );
    }
  }

  void decrement() {
    if (state case Add2AppStateReady(data: final current)) {
      emit(
        Add2AppStateReady(
          current.copyWith(count: current.count - 1, lastUpdatedBy: 'flutter'),
        ),
      );
    }
  }

  void reset() {
    if (state case Add2AppStateReady(data: final current)) {
      emit(
        Add2AppStateReady(current.copyWith(count: 0, lastUpdatedBy: 'flutter')),
      );
    }
  }
}
