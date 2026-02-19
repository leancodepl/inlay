import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:leancode_add2app/src/storage/add2app_snapshot_store.dart';
import 'package:meta/meta.dart';

/// Mixin for cubits that need to observe multiple `Add2AppSnapshotStore`s.
///
/// Use this instead of `Add2AppCubit` when the cubit's state is derived from
/// more than one store. Call [observeStore] in the constructor or init method
/// for each store — subscriptions are automatically cancelled on [close].
mixin Add2AppStoreObserver<State> on Cubit<State> {
  final _storeSubscriptions = <StreamSubscription<Object?>>[];

  /// Subscribe to [store]'s reactive stream. [onSnapshot] is called whenever
  /// the store changes from another engine or native code.
  @protected
  void observeStore<S>(
    Add2AppSnapshotStore<S> store,
    void Function(S snapshot) onSnapshot,
  ) {
    _storeSubscriptions.add(store.stream.listen(onSnapshot));
  }

  @override
  Future<void> close() {
    for (final sub in _storeSubscriptions) {
      sub.cancel();
    }
    return super.close();
  }
}
