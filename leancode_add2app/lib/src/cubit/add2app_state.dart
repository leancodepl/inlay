/// State wrapper for `Add2AppCubit` that handles the async loading phase.
///
/// The cubit starts in [Add2AppStateLoading] while the initial snapshot is
/// fetched from the platform, then transitions to [Add2AppStateReady] once
/// data is available.
sealed class Add2AppState<T> {
  const Add2AppState();

  /// Returns the data if in the ready state, or `null` if still loading.
  T? get dataOrNull => switch (this) {
    Add2AppStateReady(:final data) => data,
    _ => null,
  };

  /// Returns the data if in the ready state, or throws [StateError].
  T get requireData => switch (this) {
    Add2AppStateReady(:final data) => data,
    _ => throw StateError('Add2AppState is not ready'),
  };

  /// Whether the cubit is still loading the initial snapshot.
  bool get isLoading => this is Add2AppStateLoading;
}

/// The cubit is loading the initial snapshot from the platform.
final class Add2AppStateLoading<T> extends Add2AppState<T> {
  const Add2AppStateLoading();
}

/// The cubit has data available.
final class Add2AppStateReady<T> extends Add2AppState<T> {
  const Add2AppStateReady(this.data);

  /// The current snapshot data.
  final T data;
}
