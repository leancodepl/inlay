/// Base interface for generated stores that support snapshot read/write.
///
/// Generated store classes implement this interface, enabling `Add2AppCubit`
/// to work generically with any store.
abstract interface class Add2AppSnapshotStore<Snapshot> {
  /// Reactive stream that fires when entries change from another engine or
  /// native code. The writing engine is not notified about its own writes.
  Stream<Snapshot> get stream;

  /// Read all fields from the platform and return an immutable snapshot.
  Future<Snapshot> getSnapshot();

  /// Persist [snapshot] to the platform storage. When [previous] is provided,
  /// only fields that differ between [previous] and [snapshot] are written,
  /// reducing unnecessary cross-engine notifications.
  Future<void> writeSnapshot(Snapshot snapshot, {Snapshot? previous});
}
