# State Management

The framework provides a shared key-value storage layer that stays synchronized across all Flutter engines and native code. Any change made from one place is automatically broadcast to all other consumers.

On the Flutter side, you can use the generated store directly or pair it with the optional `Add2AppCubit` helper for a reactive UI pattern. Native code (iOS/Android) accesses the same data through a `NativeStorageScope`.

## Background for Native Developers

A few Flutter/Dart concepts referenced in this guide:

- **Cubit** — A lightweight state holder from the [bloc](https://bloclibrary.dev/) library. Think of it as a ViewModel that emits immutable state objects. The framework's `Add2AppCubit` is an optional convenience built on top of it. **You do not need to use Cubits** — the store and storage layers work independently.
- **Dart isolate** — Each Flutter engine runs in its own isolate (similar to a thread with its own memory). This is why cross-engine synchronization goes through the platform layer rather than shared memory.
- **Stream** — Dart's equivalent of reactive observables (like `Flow` in Kotlin or `AsyncSequence`/Combine publishers in Swift). Stores expose a `stream` that emits whenever data changes.

## Architecture Overview

```
┌─────────────┐   ┌─────────────┐   ┌──────────────┐
│ Flutter      │   │ Flutter     │   │ Native       │
│ Engine 1     │   │ Engine 2    │   │ (iOS/Android) │
│              │   │             │   │              │
│  Store       │   │  Store      │   │ StorageScope │
│    ↕         │   │    ↕        │   │      ↕       │
│ KeyValue     │   │ KeyValue    │   │              │
│ Storage      │   │ Storage     │   │              │
└──────┬───────┘   └──────┬──────┘   └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                 ┌────────┴────────┐
                 │   Platform      │
                 │ KeyValueStorage │
                 │  (in-memory)    │
                 └─────────────────┘
```

All reads and writes go through a platform-side in-memory dictionary. When any consumer writes a value, all *other* consumers are notified. The originating writer does not receive its own notification, preventing loops.

## Defining Stores

Stores are defined as plain Dart classes with annotations. The code generator produces typed wrappers with getters, setters, reactive streams, and snapshot support.

```dart
@Add2AppStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    @Add2AppStoreKey() required this.contactId,
    this.mute = false,
    this.showPreviews = true,
    this.sound = 'Default',
    this.vibration = VibrationLevel.normal,
  });

  final String contactId;
  final bool mute;
  final bool showPreviews;
  final String sound;
  final VibrationLevel vibration;
}
```

### Annotations

| Annotation | Purpose |
|---|---|
| `@Add2AppStore(key: 'prefix')` | Marks a class as a store definition. The `key` sets the prefix used in storage keys. |
| `@Add2AppStoreKey()` | Marks a field as a **key segment** — it's used in the storage path to scope data, but is not stored as a value itself. |

### Storage Keys

Values are stored under keys that follow the pattern `{prefix}/{keyField}/{fieldName}`:

```
sounds_notifications/abc-123/mute
sounds_notifications/abc-123/showPreviews
sounds_notifications/abc-123/sound
```

This means different contacts (or any scoped entity) each get their own set of keys.

### Generated Output

For the store above, the generator produces:

- **`SoundsNotificationsStore`** (Dart) — A wrapper with typed async getters/setters (e.g. `getMute()`, `setMute(bool)`), a reactive `stream`, and snapshot support.
- **`SoundsNotificationsStoreSnapshot`** (Dart) — An immutable data class holding all field values, with a `copyWith` method.

## Using Stores from Flutter (Dart)

### Direct Store Usage

You can use the generated store directly — no Cubit required:

```dart
final store = SoundsNotificationsStore(
  KeyValueStorage.instance,
  contactId: 'abc-123',
);

// Read
final isMuted = await store.getMute();

// Write
await store.setMute(true);

// Read all fields at once
final snapshot = await store.getSnapshot();
print('Sound: ${snapshot.sound}, Muted: ${snapshot.mute}');

// React to changes from other engines or native code
store.stream.listen((snapshot) {
  print('External change: mute=${snapshot.mute}');
});
```

### Using with Add2AppCubit (Optional)

`Add2AppCubit` is an optional convenience layer built on the [bloc](https://bloclibrary.dev/) library. It connects a store to a reactive UI pattern by:

1. Loading the initial snapshot from the store automatically
2. Subscribing to the store's `stream` for cross-engine sync
3. Persisting changes to the store on every state change (writing only the fields that actually changed)

After construction, call `init()` to load the initial snapshot and start listening for cross-engine updates. The idiomatic way is to use Dart's cascade operator: `MyCubit(store)..init()`.

If your team already uses bloc/Cubit in Flutter, this is a natural fit. If not, you can skip it entirely and use the store directly.

**Define a Cubit:**

```dart
class SoundsNotificationsCubit
    extends Add2AppCubit<SoundsNotificationsStoreSnapshot> {
  SoundsNotificationsCubit(super.store);

  void toggleMute() {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(mute: !current.mute)));
    }
  }

  void changeSound(String sound) {
    if (state case Add2AppStateReady(data: final current)) {
      emit(Add2AppStateReady(current.copyWith(sound: sound)));
    }
  }
}
```

**Use in a widget:**

```dart
class SoundsNotificationsScreen extends StatelessWidget {
  const SoundsNotificationsScreen({super.key, required this.contactId});
  final String contactId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SoundsNotificationsCubit(
        SoundsNotificationsStore(
          KeyValueStorage.instance,
          contactId: contactId,
        ),
      )..init(),
      child: BlocBuilder<SoundsNotificationsCubit,
          Add2AppState<SoundsNotificationsStoreSnapshot>>(
        builder: (context, state) => switch (state) {
          Add2AppStateLoading() =>
            const Center(child: CircularProgressIndicator()),
          Add2AppStateReady(:final data) => ListView(
            children: [
              SwitchListTile(
                title: const Text('Mute'),
                value: data.mute,
                onChanged: (_) =>
                    context.read<SoundsNotificationsCubit>().toggleMute(),
              ),
            ],
          ),
        },
      ),
    );
  }
}
```

**`Add2AppState`** is a sealed type with two variants:

| Variant | Description |
|---|---|
| `Add2AppStateLoading` | The initial snapshot is still being loaded from the store. |
| `Add2AppStateReady(data)` | The snapshot is loaded and ready. |

**Observing multiple stores** in a single Cubit is supported via the `Add2AppStoreObserver` mixin.

## Using Stores from Native Code

Native code accesses the same storage through a `NativeStorageScope`. You create a scope, read/write values, and optionally observe changes.

### iOS (Swift)

```swift
let scope = KeyValueStorageImpl.shared.createScope()

// Read
let isMuted = scope.get(key: "sounds_notifications/abc-123/mute")

// Write (automatically broadcast to Flutter engines and other scopes)
scope.put(key: "sounds_notifications/abc-123/mute", value: "true")

// Observe changes made by Flutter or other native scopes
scope.startObserving { entries in
    for entry in entries {
        print("\(entry.key) = \(entry.value)")
    }
}

// Stop observing and clean up
scope.stopObserving()
scope.dispose()
```

For **SwiftUI**, use the `Add2AppStorageObserver` wrapper which manages the scope lifecycle:

```swift
struct SettingsView: View {
    @StateObject private var storage = Add2AppStorageObserver()

    var body: some View {
        // Read: storage.get(key: "...")
        // Write: storage.put(key: "...", value: "...")
    }
}
```

### Android (Kotlin)

```kotlin
val scope = KeyValueStorageImpl.createScope()

// Read
val isMuted = scope.get("sounds_notifications/abc-123/mute")

// Write (automatically broadcast to Flutter engines and other scopes)
scope.put("sounds_notifications/abc-123/mute", "true")

// Observe changes made by Flutter or other native scopes
scope.startObserving { entries ->
    entries.forEach { println("${it.key} = ${it.value}") }
}

// Stop observing and clean up
scope.stopObserving()
scope.dispose()
```

## KeyValueStorage (Low-Level Dart API)

`KeyValueStorage` is the Dart singleton underneath the generated stores. You can use it directly for ad-hoc values that don't warrant a full store definition.

Initialize once per engine before `runApp`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await KeyValueStorage.instance.init();
```

### API

```dart
// String
await KeyValueStorage.instance.putString('key', 'value');
final value = await KeyValueStorage.instance.getString('key');

// Bool
await KeyValueStorage.instance.putBool('key', value: true);
final flag = await KeyValueStorage.instance.getBool('key');

// JSON
await KeyValueStorage.instance.putJson('key', {'nested': 'data'});
final json = await KeyValueStorage.instance.getJson('key');

// Bulk operations
await KeyValueStorage.instance.putAll([
  StorageEntry(key: 'a', value: '1'),
  StorageEntry(key: 'b', value: '2'),
]);
final entries = await KeyValueStorage.instance.getByPrefix('sounds_');

// Reactive stream — emits when OTHER writers change values
KeyValueStorage.instance.stream.listen((entries) {
  // handle external changes
});
```

## Cross-Engine Synchronization

Here's what happens when a value is changed:

1. **Write** — A consumer (Flutter store, Cubit, or native scope) writes a value. The write goes through the platform via a Pigeon channel.
2. **Platform broadcast** — The platform-side in-memory store updates and notifies all registered consumers *except* the writer.
3. **Flutter engines receive** — Each other Flutter engine's `KeyValueStorage.stream` emits the change. If using a generated store, the store's `stream` filters for relevant keys and emits a new snapshot. If using `Add2AppCubit`, the Cubit automatically updates its state.
4. **Native scopes receive** — Registered `NativeStorageScope` observers receive the change via their callback.

### Thread Safety

| Concern | Solution |
|---|---|
| Platform store (iOS) | Concurrent `DispatchQueue` with barrier writes |
| Platform store (Android) | `ConcurrentHashMap` with synchronized observer registries |
| Dart isolates | Each engine is its own isolate; updates are delivered asynchronously via streams |
| Self-notification | Each writer is tagged with an ID; notifications skip the originator |
| Conflicts | Last-write-wins; `writeSnapshot` diffs against the previous state and only writes changed fields, minimizing conflict surface |
| App backgrounding | `KeyValueStorage` performs a full sync on `AppLifecycleState.resumed` to catch changes made while the engine was inactive |

## When to Use What

| Approach | Type Safety | Cross-engine sync | Best for |
|---|---|---|---|
| `@Add2AppStore` + `Add2AppCubit` | Full (typed fields, snapshots) | Automatic | Flutter screens that need reactive state tied to storage |
| `@Add2AppStore` (direct) | Full | Manual (listen to `stream`) | Flutter code that doesn't use bloc |
| `KeyValueStorage` (raw) | Manual (string keys/values) | Manual (listen to `stream`) | Ad-hoc values, one-off reads/writes |
| `NativeStorageScope` | Manual (string keys/values) | Via `startObserving` | Native code (iOS/Android) |
