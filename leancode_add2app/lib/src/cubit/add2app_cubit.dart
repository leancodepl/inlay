import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:leancode_add2app/src/cubit/add2app_state.dart';
import 'package:leancode_add2app/src/storage/add2app_snapshot_store.dart';

/// A [Cubit] backed by an [Add2AppSnapshotStore].
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
abstract class Add2AppCubit<State> extends Cubit<Add2AppState<State>> {
  Add2AppCubit(this._store) : super(const Add2AppStateLoading());

  final Add2AppSnapshotStore<State> _store;
  StreamSubscription<State>? _storeSub;

  Future<void> init() async {
    final snapshot = await _store.getSnapshot();
    super.emit(Add2AppStateReady(snapshot));
    _storeSub = _store.stream.listen((snapshot) {
      super.emit(Add2AppStateReady(snapshot));
    });
  }

  /// Updates local state AND persists changed fields to the store.
  ///
  /// Only [Add2AppStateReady] states trigger a write; emitting
  /// [Add2AppStateLoading] is a no-op on the store side.
  ///
  /// The write is fire-and-forget — local state updates optimistically while
  /// persistence happens asynchronously.
  @override
  void emit(Add2AppState<State> state) {
    final previous = this.state.dataOrNull;
    super.emit(state);
    if (state case Add2AppStateReady(:final data)) {
      _store.writeSnapshot(data, previous: previous);
    }
  }

  @override
  Future<void> close() {
    _storeSub?.cancel();
    return super.close();
  }
}
