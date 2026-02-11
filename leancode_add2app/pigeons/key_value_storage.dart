import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/storage/key_value_storage.g.dart',
    kotlinOut: 'android/src/main/kotlin/co/leancode/add2app/storage/KeyValueStorageApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'co.leancode.add2app.storage',
    ),
    swiftOut: 'ios/Classes/KeyValueStorageApi.g.swift',
    dartPackageName: 'leancode_add2app',
  ),
)

/// A generic key-value entry stored on the platform side.
class StorageEntry {
  StorageEntry({required this.key, required this.value});

  /// The key for this entry.
  String key;

  /// The JSON-encoded value for this entry.
  /// We use String (JSON) so Pigeon can transport any structured data.
  String value;
}

/// Batch of changed entries, used for change notifications.
class StorageChangeEvent {
  StorageChangeEvent({required this.entries});

  /// The entries that changed (new values).
  List<StorageEntry> entries;
}

/// Host API — Flutter calls into platform (Android/iOS).
/// The platform owns the data; Flutter reads/writes through this API.
/// Uses TaskQueue.serialBackgroundThread for thread-safety.
@HostApi()
abstract class KeyValueStorageHostApi {
  /// Put a value into the storage. Overwrites if key already exists.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void put(StorageEntry entry);

  /// Put multiple values at once (atomic batch).
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void putAll(List<StorageEntry> entries);

  /// Get a value by key. Returns null if not found.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  StorageEntry? get(String key);

  /// Get all values whose keys start with the given prefix.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<StorageEntry> getByPrefix(String prefix);

  /// Remove a value by key. Returns true if the key existed.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool remove(String key);

  /// Remove all values whose keys start with the given prefix.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void removeByPrefix(String prefix);

  /// Get all stored entries (full dump).
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<StorageEntry> getAll();

  /// Clear all storage.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void clear();
}

/// Flutter API — Platform calls into Flutter to notify about changes.
/// Each Flutter engine isolate registers this so it gets notified when
/// any other engine (or native code) changes storage.
@FlutterApi()
abstract class KeyValueStorageFlutterApi {
  /// Called when entries in the storage have changed.
  void onStorageChanged(StorageChangeEvent event);
}
