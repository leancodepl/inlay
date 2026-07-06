import 'dart:async';

import 'package:flutter/material.dart';

import '../storage/key_value_storage.dart';

/// App-level appearance settings shared between the native host and every
/// Flutter engine: theme mode and an optional in-app locale override.
///
/// A fresh engine per screen means Flutter cannot rely on widget state for
/// app-level settings - each engine starts blank. [InlayAppearance] keeps
/// the settings in the framework's cross-engine storage instead, so every
/// engine (including ones created later) reads the current values at
/// startup and follows changes live, and native code can drive them.
///
/// From native code:
///
/// ```swift
/// InlayAppearance.shared.themeMode = .dark
/// InlayAppearance.shared.localeLanguageTag = "pl-PL"
/// ```
///
/// ```kotlin
/// InlayAppearance.themeMode = InlayThemeMode.DARK
/// InlayAppearance.localeLanguageTag = "pl-PL"
/// ```
///
/// From the Dart entrypoint, initialize after [KeyValueStorage.init] and
/// rebuild the app when it changes:
///
/// ```dart
/// await InlayAppearance.instance.init();
///
/// runApp(
///   ListenableBuilder(
///     listenable: InlayAppearance.instance,
///     builder: (context, _) => MaterialApp.router(
///       themeMode: InlayAppearance.instance.themeMode,
///       theme: ThemeData.light(),
///       darkTheme: ThemeData.dark(),
///       locale: InlayAppearance.instance.locale,
///       // ...
///     ),
///   ),
/// );
/// ```
///
/// Flutter code can also change the settings ([setThemeMode], [setLocale]);
/// the change propagates to all other engines and native scopes the same
/// way.
class InlayAppearance extends ChangeNotifier {
  InlayAppearance._();

  static final instance = InlayAppearance._();

  /// Storage key for the theme mode; reserved by the framework.
  static const themeModeKey = '__inlay/appearance/themeMode';

  /// Storage key for the locale override; reserved by the framework.
  static const localeKey = '__inlay/appearance/locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  StreamSubscription<List<StorageEntry>>? _subscription;

  /// The current theme mode. [ThemeMode.system] when never set.
  ThemeMode get themeMode => _themeMode;

  /// The in-app locale override, or `null` to follow the system locale.
  Locale? get locale => _locale;

  /// Loads the current values and starts following cross-engine changes.
  ///
  /// Call once per isolate after [KeyValueStorage.init], before `runApp`.
  Future<void> init() async {
    final storage = KeyValueStorage.instance;
    _subscription ??= storage.stream.listen(_onEntriesChanged);
    _themeMode = _decodeThemeMode(await storage.getString(themeModeKey));
    _locale = _decodeLocale(await storage.getString(localeKey));
    notifyListeners();
  }

  /// Sets the theme mode for the whole app - all engines and native scopes.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await KeyValueStorage.instance.putString(themeModeKey, mode.name);
  }

  /// Sets the in-app locale override for the whole app.
  ///
  /// Pass `null` to follow the system locale again.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await KeyValueStorage.instance.remove(localeKey);
    } else {
      await KeyValueStorage.instance.putString(
        localeKey,
        locale.toLanguageTag(),
      );
    }
  }

  void _onEntriesChanged(List<StorageEntry> entries) {
    var changed = false;
    for (final entry in entries) {
      if (entry.key == themeModeKey) {
        _themeMode = _decodeThemeMode(entry.value);
        changed = true;
      } else if (entry.key == localeKey) {
        _locale = _decodeLocale(entry.value);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  static ThemeMode _decodeThemeMode(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static Locale? _decodeLocale(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parts = raw.split('-');
    if (parts.length >= 2) {
      return Locale(parts.first, parts.last);
    }
    return Locale(parts.first);
  }

  /// Detaches from the current [KeyValueStorage.instance] and restores
  /// defaults, so each test starts clean after swapping in a fake storage.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _subscription?.cancel();
    _subscription = null;
    _themeMode = ThemeMode.system;
    _locale = null;
  }
}
