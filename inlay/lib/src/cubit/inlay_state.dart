/// State wrapper for `InlayCubit` that handles the async loading phase.
///
/// The cubit starts in [InlayStateLoading] while the initial snapshot is
/// fetched from the platform, then transitions to [InlayStateReady] once
/// data is available.
sealed class InlayState<T> {
  const InlayState();

  /// Returns the data if in the ready state, or `null` if still loading.
  T? get dataOrNull => switch (this) {
    InlayStateReady(:final data) => data,
    _ => null,
  };

  /// Returns the data if in the ready state, or throws [StateError].
  T get requireData => switch (this) {
    InlayStateReady(:final data) => data,
    _ => throw StateError('InlayState is not ready'),
  };

  /// Whether the cubit is still loading the initial snapshot.
  bool get isLoading => this is InlayStateLoading;
}

/// The cubit is loading the initial snapshot from the platform.
final class InlayStateLoading<T> extends InlayState<T> {
  const InlayStateLoading();
}

/// The cubit has data available.
final class InlayStateReady<T> extends InlayState<T> {
  const InlayStateReady(this.data);

  /// The current snapshot data.
  final T data;
}
