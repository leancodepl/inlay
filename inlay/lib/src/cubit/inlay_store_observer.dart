import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inlay/src/storage/inlay_snapshot_store.dart';
import 'package:meta/meta.dart';

/// Mixin for cubits that need to observe multiple `InlaySnapshotStore`s.
///
/// Use this instead of `InlayCubit` when the cubit's state is derived from
/// more than one store. Call [observeStore] in the constructor or init method
/// for each store — subscriptions are automatically cancelled on [close].
mixin InlayStoreObserver<State> on Cubit<State> {
  final _storeSubscriptions = <StreamSubscription<Object?>>[];

  /// Subscribe to [store]'s reactive stream. [onSnapshot] is called whenever
  /// the store changes from another engine or native code.
  @protected
  void observeStore<S>(
    InlaySnapshotStore<S> store,
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
