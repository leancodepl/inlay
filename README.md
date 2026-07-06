# Flutter Inlay

An opinionated Flutter add-to-app framework providing **type-safe navigation** and **cross-platform state sharing** for apps that embed Flutter inside a native iOS or Android host.

## Why

Integrating Flutter into an existing native app is painful:

- **Navigation** - There are no official guidelines for seamless navigation between native and Flutter screens. The typical approach is raw `MethodChannel` calls with arbitrary strings, which is error-prone and not type-safe.
- **State** - There is no standard way to share data between native code and Flutter, especially when multiple Flutter screens (engines) are involved.

This framework solves both problems with a code-generation-driven, type-safe approach. Engine management (based on `FlutterEngineGroup`) is handled for you behind the scenes.

## Features

- **Navigation** - Type-safe routing between Native and Flutter screens (in both directions), with code-generated route classes for Dart, Swift, and Kotlin.
- **Shared State** - A key-value storage layer that stays in sync across all Flutter engines and native code. Changes made anywhere are automatically broadcast to all other consumers.
- **Engine Management** - The framework creates and destroys Flutter engines automatically. You never interact with `FlutterEngineGroup` directly (unless you want to).
- **Theme & Locale Propagation** - `InlayAppearance` lets the host drive dark mode and an in-app language override across every Flutter engine, live (see [State Management](docs_internal/state.md)).

## Quick Start

### 1. Define routes (Dart)

```dart
// A Flutter screen - navigable from native or from other Flutter screens
@InlayFlutterRoute('/sounds-notifications/:contactId')
class SoundsNotificationsPage {
  const SoundsNotificationsPage({required this.contactId});
  final String contactId;
}

// A Flutter dialog - rendered by Flutter over a native screen
@InlayFlutterDialog('/confirm-delete/:itemId')
class ConfirmDeleteDialog {
  const ConfirmDeleteDialog({required this.itemId});
  final String itemId;
}

// A native screen - navigable from Flutter
@InlayNativeRoute()
class NativeEditProfilePage {
  const NativeEditProfilePage({required this.contactId});
  final String contactId;
}
```

Run code generation to produce type-safe route classes for **Dart, Swift, and Kotlin**.

### 2. Navigate

From **Dart** (Flutter):

```dart
// Open a Flutter screen (creates a new native container with a Flutter engine)
await InlayNavigator.instance.push(
  SoundsNotificationsPage(contactId: 'abc-123'),
);

// Open a native screen from Flutter
await InlayNavigator.instance.push(
  NativeEditProfilePage(contactId: 'abc-123').toNativeRoute(),
);
```

From **Swift** (iOS):

```swift
InlayNavigator.shared.push(
  from: viewController,
  route: SoundsNotificationsPage(contactId: "abc-123"),
  animated: true
)
```

From **Kotlin** (Android):

```kotlin
InlayNavigator.push(context, SoundsNotificationsPage(contactId = "abc-123"))
```

For Jetpack Compose support add the optional `inlay_compose` plugin alongside `inlay` in your module's `pubspec.yaml`. Projects that don't use Compose depend only on `inlay` - no Compose transitive dependencies. See the [Navigation](docs_internal/navigation.md) guide for details.

### 3. Share state

Define a store (Dart):

```dart
@InlayStore(key: 'sounds_notifications')
class SoundsNotificationsStore {
  const SoundsNotificationsStore({
    @InlayStoreKey() required this.contactId,
    this.mute = false,
    this.sound = 'Default',
  });

  final String contactId;
  final bool mute;
  final String sound;
}
```

Read and write from native - **Swift**:

```swift
let scope = KeyValueStorageImpl.shared.createScope()
let store = SoundsNotificationsStore(storage: scope, contactId: "abc-123")

store.mute = true

scope.startObserving { entries in
    if store.containsChanges(in: entries) {
        // reload from store typed properties
    }
}
```

Read and write from native - **Kotlin**:

```kotlin
val scope = KeyValueStorageImpl.createScope()
val store = SoundsNotificationsStore(scope, contactId = "abc-123")

store.mute = true

scope.startObserving { entries ->
    if (store.containsChanges(entries)) {
        // reload from store typed properties
    }
}
```

On the Flutter side, the generated store can be used directly or combined with the optional `InlayCubit` helper (see the [State Management](docs_internal/state.md) guide).

## Documentation

- [Navigation](docs_internal/navigation.md) - Route definitions, dialogs & bottom sheets, cross-boundary navigation, go_router & auto_route integration
- [State Management](docs_internal/state.md) - Stores, native access, optional Cubit integration, cross-engine sync
- [Testing](docs_internal/testing.md) - Widget-testing screens that navigate and use stores, via `package:inlay/testing.dart` fakes
