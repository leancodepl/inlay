import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'key_value_storage.g.dart';

export 'key_value_storage.g.dart' show StorageEntry;

/// Framework-level key-value storage.
///
/// All reads go through the platform (the single source of truth).
/// There is no local cache — every [getString], [getBool], etc. is a
/// `Future` that round-trips to the host via Pigeon.  This eliminates an
/// entire class of staleness bugs.
///
/// Change notifications arrive via [stream]:
/// - Real-time pushes from the platform when *another* engine or Android
///   changes a value (the writing engine is **not** notified about its own
///   writes — the framework suppresses self-notifications).
/// - A full re-sync on [AppLifecycleState.resumed] as a safety net.
class KeyValueStorage
    with WidgetsBindingObserver
    implements KeyValueStorageFlutterApi {
  factory KeyValueStorage() => instance;

  KeyValueStorage._();

  static final instance = KeyValueStorage._();

  final _hostApi = KeyValueStorageHostApi();
  final _controller = StreamController<List<StorageEntry>>.broadcast();

  var _initialized = false;

  // ── Initialisation ──────────────────────────────────────────────────

  /// Call once per isolate, before `runApp`.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    KeyValueStorageFlutterApi.setUp(this);
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _emitFullSync();
    }
  }

  // ── Push notification from platform ───────────────────────────────

  @override
  void onStorageChanged(StorageChangeEvent event) {
    _controller.add(event.entries);
  }

  // ── Reactive stream ───────────────────────────────────────────────

  /// Fires whenever entries change (from another engine or Android).
  Stream<List<StorageEntry>> get stream => _controller.stream;

  // ── String ────────────────────────────────────────────────────────

  Future<void> putString(String key, String value) async {
    await _hostApi.put(StorageEntry(key: key, value: value));
  }

  Future<String?> getString(String key) async {
    final entry = await _hostApi.get(key);
    return entry?.value;
  }

  // ── Bool ──────────────────────────────────────────────────────────

  Future<void> putBool(String key, {required bool value}) async {
    await putString(key, value.toString());
  }

  Future<bool?> getBool(String key) async {
    final raw = await getString(key);
    if (raw == null) {
      return null;
    }
    return raw == 'true';
  }

  // ── JSON (Map) ────────────────────────────────────────────────────

  Future<void> putJson(String key, Map<String, dynamic> value) async {
    await putString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null) {
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Remove ────────────────────────────────────────────────────────

  Future<bool> remove(String key) {
    return _hostApi.remove(key);
  }

  Future<void> removeByPrefix(String prefix) async {
    await _hostApi.removeByPrefix(prefix);
  }

  // ── Bulk ──────────────────────────────────────────────────────────

  Future<List<StorageEntry>> getAll() {
    return _hostApi.getAll();
  }

  Future<List<StorageEntry>> getByPrefix(String prefix) {
    return _hostApi.getByPrefix(prefix);
  }

  Future<void> clear() async {
    await _hostApi.clear();
  }

  // ── Internal ──────────────────────────────────────────────────────

  /// Fetch everything from the platform and emit it as a change event so
  /// listening widgets rebuild with the freshest data.
  Future<void> _emitFullSync() async {
    try {
      final all = await _hostApi.getAll();
      if (all.isNotEmpty) {
        _controller.add(all);
      }
    } catch (err) {
      debugPrint('KeyValueStorage: full sync failed: $err');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
  }
}
