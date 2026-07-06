import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../storage/key_value_storage.dart';
import '../storage/key_value_storage.g.dart';

/// In-memory [KeyValueStorage] double for widget and unit tests.
///
/// Behaves like the real storage without any platform channel:
/// - values live in the public [data] map,
/// - writes do **not** notify [stream] (mirroring the real self-notification
///   suppression),
/// - [simulateExternalChange] plays the role of another engine or native
///   code writing to the store.
///
/// Install it by overriding the singleton:
///
/// ```dart
/// final storage = FakeKeyValueStorage();
/// KeyValueStorage.instance = storage;
/// ```
class FakeKeyValueStorage
    with WidgetsBindingObserver
    implements KeyValueStorage {
  /// Backing store, exposed for direct inspection and seeding in tests.
  final Map<String, String> data = {};

  final _controller = StreamController<List<StorageEntry>>.broadcast();

  /// Applies [entries] and notifies [stream] listeners - what a write from
  /// another engine or native code looks like to this isolate.
  void simulateExternalChange(List<StorageEntry> entries) {
    for (final entry in entries) {
      if (entry.value.isEmpty) {
        data.remove(entry.key);
      } else {
        data[entry.key] = entry.value;
      }
    }
    _controller.add(entries);
  }

  @override
  Future<void> init() async {}

  @override
  void onStorageChanged(StorageChangeEvent event) {
    _controller.add(event.entries);
  }

  @override
  Stream<List<StorageEntry>> get stream => _controller.stream;

  @override
  Future<void> putString(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> putBool(String key, {required bool value}) async {
    data[key] = value.toString();
  }

  @override
  Future<bool?> getBool(String key) async {
    final raw = data[key];
    return raw == null ? null : raw == 'true';
  }

  @override
  Future<void> putJson(String key, Map<String, dynamic> value) async {
    data[key] = jsonEncode(value);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = data[key];
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> remove(String key) async => data.remove(key) != null;

  @override
  Future<void> removeByPrefix(String prefix) async {
    data.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> putAll(List<StorageEntry> entries) async {
    for (final entry in entries) {
      data[entry.key] = entry.value;
    }
  }

  @override
  Future<List<StorageEntry>> getAll() async => [
    for (final e in data.entries) StorageEntry(key: e.key, value: e.value),
  ];

  @override
  Future<List<StorageEntry>> getByPrefix(String prefix) async => [
    for (final e in data.entries)
      if (e.key.startsWith(prefix)) StorageEntry(key: e.key, value: e.value),
  ];

  @override
  Future<void> clear() async {
    data.clear();
  }

  @override
  void dispose() {
    _controller.close();
  }
}
