import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inlay/src/cubit/inlay_state.dart';
import 'package:inlay/src/storage/inlay_snapshot_store.dart';

/// A [Cubit] backed by an [InlaySnapshotStore].
///
/// Handles:
/// - Loading the initial snapshot from the platform.
/// - Subscribing to the store's reactive stream for cross-engine sync.
/// - Persisting state changes via the overridden [emit] method.
///
/// Subclasses add domain methods that read [state] and call [emit] with new
/// snapshots. The overridden [emit] writes changed fields to the platform,
/// propagating updates to all other Flutter engines, isolates, and native code.
///
/// Internal updates (initial load, store stream) use [super.emit] to bypass
/// persistence and prevent write-back loops. This is safe because Dart is
/// single-threaded within an isolate.
abstract class InlayCubit<State> extends Cubit<InlayState<State>> {
  InlayCubit(this._store) : super(const InlayStateLoading());

  final InlaySnapshotStore<State> _store;
  StreamSubscription<State>? _storeSub;

  Future<void> init() async {
    final snapshot = await _store.getSnapshot();
    super.emit(InlayStateReady(snapshot));
    _storeSub = _store.stream.listen((snapshot) {
      super.emit(InlayStateReady(snapshot));
    });
  }

  /// Updates local state AND persists changed fields to the store.
  ///
  /// Only [InlayStateReady] states trigger a write; emitting
  /// [InlayStateLoading] is a no-op on the store side.
  ///
  /// The write is fire-and-forget — local state updates optimistically while
  /// persistence happens asynchronously.
  @override
  void emit(InlayState<State> state) {
    final previous = this.state.dataOrNull;
    super.emit(state);
    if (state case InlayStateReady(:final data)) {
      _store.writeSnapshot(data, previous: previous);
    }
  }

  @override
  Future<void> close() {
    _storeSub?.cancel();
    return super.close();
  }
}
