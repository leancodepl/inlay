import 'package:example_module/src/generated/stores.g.dart';
import 'package:example_module/src/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

void main() {
  late FakeKeyValueStorage storage;

  setUp(() {
    storage = FakeKeyValueStorage();
    KeyValueStorage.instance = storage;
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(userId: '42', badges: []),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders values seeded through the generated store', (
    tester,
  ) async {
    await UserPreferencesStore(storage, userId: '42').setDisplayName('Marcin');

    await pumpProfile(tester);

    expect(find.text('Display name: Marcin'), findsOneWidget);
  });

  testWidgets('persists changes back to the store', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Toggle dark mode'));
    await tester.pumpAndSettle();

    expect(find.text('Dark mode: on'), findsOneWidget);
    expect(
      await UserPreferencesStore(storage, userId: '42').getDarkMode(),
      isTrue,
    );
  });

  testWidgets('reacts to a change from another engine or native code', (
    tester,
  ) async {
    await pumpProfile(tester);

    // What a write from native code (or another engine) looks like from
    // this isolate's perspective.
    storage.simulateExternalChange([
      StorageEntry(
        key: 'user_preferences/42/displayName',
        value: 'From native',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Display name: From native'), findsOneWidget);
  });
}
