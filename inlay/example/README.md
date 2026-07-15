# inlay example

A minimal tour of the inlay API. For a complete, runnable project — a Flutter
module plus native iOS and Android host apps exercising every feature — see the
[`example/` directory](https://github.com/leancodepl/inlay/tree/main/example)
in the repository.

Route and store classes are generated from annotated Dart schemas by
[`inlay_gen`](https://pub.dev/packages/inlay_gen).

## 1. Define routes and stores (Dart schema)

```dart
// A Flutter screen — navigable from native or from other Flutter screens.
@InlayFlutterRoute('/sounds-notifications/:contactId')
class SoundsNotificationsPage {
  const SoundsNotificationsPage({required this.contactId});
  final String contactId;
}

// A native screen — navigable from Flutter.
@InlayNativeRoute()
class NativeEditProfilePage {
  const NativeEditProfilePage({required this.contactId});
  final String contactId;
}

// A key-value store synced across every engine and native code.
@InlayStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    @InlayStoreKey() required this.contactId,
    this.mute = false,
  });

  final String contactId;
  final bool mute;
}
```

Running code generation produces type-safe route and store classes for Dart,
Swift, and Kotlin.

## 2. Navigate

```dart
// Open a Flutter screen (a new native container with its own engine).
await InlayNavigator.instance.push(
  SoundsNotificationsPage(contactId: 'abc-123'),
);

// Open a native screen from Flutter.
await InlayNavigator.instance.push(
  NativeEditProfilePage(contactId: 'abc-123').toNativeRoute(),
);
```

## 3. Share state

```dart
// Read and write the generated store from Dart. Writes are broadcast to every
// other Flutter engine and native scope in real time.
final store = SoundsNotificationsStore(
  KeyValueStorage.instance,
  contactId: 'abc-123',
);
await store.setMute(true);
```

See the [Navigation](https://github.com/leancodepl/inlay/blob/main/docs/navigation.md)
and [State Management](https://github.com/leancodepl/inlay/blob/main/docs/state.md)
guides for the full API.
