# Testing

Screens in an add-to-app module depend on two singletons that talk to the host over
platform channels: `InlayNavigator` and `KeyValueStorage`. In plain widget tests there is
no host, so those calls would throw `MissingPluginException`. `package:inlay/testing.dart`
ships in-memory fakes, and both singletons expose a `@visibleForTesting` instance setter:

```dart
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

setUp(() {
  KeyValueStorage.instance = FakeKeyValueStorage();
  InlayNavigator.instance = FakeInlayNavigator();
});
```

## FakeInlayNavigator

Records instead of navigating:

- `pushedRoutes` - typed routes passed to `push()`, in call order.
- `pushedPages` - raw `PageSettings` from all dispatch methods (`pushFlutterRoute`,
  `pushNativeRoute`, `presentFlutterDialog`), including those produced by `push()`.
- `popCount` - container pops; `maybePop` still pops an in-Flutter route when it can.
- `nativePopGestureEnabled` - last value passed to `setNativePopGestureEnabled`.

## FakeKeyValueStorage

In-memory map with the real storage's semantics:

- `data` - the raw backing map for inspection/seeding. Prefer seeding through the
  generated store wrappers, which use the production key encoding.
- Writes do **not** notify `stream` (matching the platform's self-notification
  suppression).
- `simulateExternalChange(entries)` - applies entries and fires `stream`; this is what a
  write from another engine or native code looks like to the isolate under test. Covers
  the full store → `InlayCubit` → widget rebuild chain.

## Reference tests

`example/example_module/test/` contains widget tests using both fakes
(`greeting_screen_test.dart`, `profile_screen_test.dart`). Both hosts also have UI
tests that cross the boundary for real, asserting on Flutter-rendered content through
the accessibility tree:

- **iOS** - XCUITests in `example_ios/UITests/`: plugin registration on a pushed
  engine, and a dialog's typed `Bool` result delivered back to native.
- **Android** - UiAutomator instrumentation tests in
  `example_android/app/src/androidTest/`: the same two flows plus `InlayAppearance`
  locale propagation into a newly created engine. Run with
  `./gradlew connectedDebugAndroidTest` (needs a connected device/emulator). Flutter
  exposes its semantics as content descriptions, so the shared `waitForAny` helper
  matches `text` and `desc` selectors alike.
