import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

void main() {
  late FakeKeyValueStorage storage;

  setUp(() async {
    storage = FakeKeyValueStorage();
    KeyValueStorage.instance = storage;
    await InlayAppearance.instance.resetForTesting();
  });

  test('defaults to system theme and system locale', () async {
    await InlayAppearance.instance.init();

    expect(InlayAppearance.instance.themeMode, ThemeMode.system);
    expect(InlayAppearance.instance.locale, isNull);
  });

  test('reads values written by the host before engine startup', () async {
    storage.data[InlayAppearance.themeModeKey] = 'dark';
    storage.data[InlayAppearance.localeKey] = 'pl-PL';

    await InlayAppearance.instance.init();

    expect(InlayAppearance.instance.themeMode, ThemeMode.dark);
    expect(InlayAppearance.instance.locale, const Locale('pl', 'PL'));
  });

  test('follows live changes from native code or another engine', () async {
    await InlayAppearance.instance.init();
    var notified = 0;
    InlayAppearance.instance.addListener(() => notified++);

    storage.simulateExternalChange([
      StorageEntry(key: InlayAppearance.themeModeKey, value: 'light'),
      StorageEntry(key: InlayAppearance.localeKey, value: 'pl'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(notified, 1);
    expect(InlayAppearance.instance.themeMode, ThemeMode.light);
    expect(InlayAppearance.instance.locale, const Locale('pl'));
  });

  test('clearing the locale override follows the system again', () async {
    storage.data[InlayAppearance.localeKey] = 'pl';
    await InlayAppearance.instance.init();

    storage.simulateExternalChange([
      // Removals arrive as empty values.
      StorageEntry(key: InlayAppearance.localeKey, value: ''),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(InlayAppearance.instance.locale, isNull);
  });

  test('setThemeMode and setLocale persist to storage', () async {
    await InlayAppearance.instance.init();

    await InlayAppearance.instance.setThemeMode(ThemeMode.dark);
    await InlayAppearance.instance.setLocale(const Locale('pl', 'PL'));

    expect(storage.data[InlayAppearance.themeModeKey], 'dark');
    expect(storage.data[InlayAppearance.localeKey], 'pl-PL');

    await InlayAppearance.instance.setLocale(null);
    expect(storage.data.containsKey(InlayAppearance.localeKey), isFalse);
  });
}
