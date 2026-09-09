---
name: inlay-testing
description: Write widget tests for Flutter screens that use inlay's InlayNavigator or KeyValueStorage singletons, using the in-memory fakes from package:inlay/testing.dart. Use when testing screens in an inlay add-to-app module that navigate, use generated stores or InlayCubit, or read/write shared state.
---

# Testing inlay screens

Screens in an inlay module depend on two singletons that talk to the native host over platform
channels: `InlayNavigator` and `KeyValueStorage`. In plain widget tests there is no host, so
those calls throw `MissingPluginException`. `package:inlay/testing.dart` ships in-memory fakes,
and both singletons expose a `@visibleForTesting` instance setter.

Canonical docs: https://github.com/leancodepl/inlay/blob/main/docs/testing.md
Reference tests (use both fakes):
https://github.com/leancodepl/inlay/tree/main/example/example_module/test

## 1. Install the fakes in `setUp`

```dart
import 'package:inlay/inlay.dart';
import 'package:inlay/testing.dart';

setUp(() {
  KeyValueStorage.instance = FakeKeyValueStorage();
  InlayNavigator.instance = FakeInlayNavigator();
});
```

Keep local references when the test needs to assert on them:

```dart
late FakeInlayNavigator navigator;
late FakeKeyValueStorage storage;

setUp(() {
  navigator = FakeInlayNavigator();
  storage = FakeKeyValueStorage();
  InlayNavigator.instance = navigator;
  KeyValueStorage.instance = storage;
});
```

## 2. Assert navigation with `FakeInlayNavigator`

It records instead of navigating:

- `pushedRoutes` — typed routes passed to `push()`, in call order. Assert with
  `expect(navigator.pushedRoutes, [isA<ContactDetailsPage>()])` and check fields on the typed
  route.
- `pushedPages` — raw `PageSettings` from all dispatch methods, including those produced by
  `push()`.
- `popCount` — container pops; `maybePop` still pops an in-Flutter route when it can.
- `nativePopGestureEnabled` — last value passed to `setNativePopGestureEnabled`.

## 3. Seed and assert state with `FakeKeyValueStorage`

An in-memory map with the real storage's semantics:

- **Seed through the generated store wrapper**, not by writing raw keys — the wrapper uses the
  production key encoding:
  ```dart
  await SoundsNotificationsStore(storage, contactId: 'abc').setMute(true);
  ```
  The raw backing map `storage.data` is available for inspection.
- Writes do **not** fire `stream` (matching the platform's self-notification suppression), so
  seeding in `setUp` won't trigger listeners.
- `simulateExternalChange(entries)` applies entries **and** fires `stream` — this is what a
  write from another engine or native code looks like to the widget under test. Use it to
  cover the full store → `InlayCubit` → widget rebuild chain, then `await tester.pump()`.

## 4. Shape of a full test

Per screen: pump the widget with its store/cubit built from the fakes, assert the initial
render (remember `InlayCubit` starts in `InlayStateLoading` — pump until ready), interact and
assert writes landed in `storage.data` / navigation landed in `navigator.pushedRoutes`, and use
`simulateExternalChange` to assert the screen reacts to changes from elsewhere. The reference
tests `greeting_screen_test.dart` and `profile_screen_test.dart` in the example module
demonstrate all of these patterns — mirror them.

## Gotchas

- Reset singletons per test (`setUp` runs per test — fresh fakes each time prevent state
  leaking between tests).
- Store getters/setters are async; `await` them in tests or you'll assert before the write.
- These fakes cover widget tests only. Real cross-boundary behavior (plugin registration,
  typed results delivered to native, appearance propagation) is host-side territory — the
  example repo has XCUITest and UiAutomator suites to mirror if you need that:
  https://github.com/leancodepl/inlay/blob/main/docs/testing.md#reference-tests
