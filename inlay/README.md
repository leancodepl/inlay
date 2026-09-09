# inlay

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
[![inlay pub.dev badge](https://img.shields.io/pub/v/inlay)](https://pub.dev/packages/inlay)

An opinionated Flutter add-to-app framework providing **type-safe navigation** and **cross-platform state sharing** for apps that embed Flutter inside a native iOS or Android host.

## Why

Integrating Flutter into an existing native app is painful:

- **Navigation** - There are no official guidelines for seamless navigation between native and Flutter screens. The typical approach is raw `MethodChannel` calls with arbitrary strings, which is error-prone and not type-safe.
- **State** - There is no standard way to share data between native code and Flutter, especially when multiple Flutter screens (engines) are involved.

inlay solves both problems with a code-generation-driven, type-safe approach. Engine management (based on `FlutterEngineGroup`) is handled for you behind the scenes.

## Features

- **Navigation** - Type-safe routing between native and Flutter screens (in both directions), with code-generated route classes for Dart, Swift, and Kotlin. Screens can return a typed **result** to their caller (declare `result:` on the route).
- **Shared State** - A key-value storage layer that stays in sync across all Flutter engines and native code. Changes made anywhere are automatically broadcast to all other consumers.
- **Engine Management** - The framework creates and destroys Flutter engines automatically. You never interact with `FlutterEngineGroup` directly (unless you want to).
- **Theme & Locale Propagation** - `InlayAppearance` lets the host drive dark mode and an in-app language override across every Flutter engine, live.
- **Dialogs & Sheets** - Flutter dialogs and bottom sheets rendered in transparent native containers over native screens, with go_router, auto_route, and imperative integrations.
- **Native Embeddings** - UIKit push/present, SwiftUI (`InlayFlutterView`, `.inlayDialog`), Android Activities and Fragments; Jetpack Compose via the optional [`inlay_compose`](https://pub.dev/packages/inlay_compose) package.

## Quick Start

Route and store classes are generated from annotated Dart schemas by [`inlay_gen`](https://pub.dev/packages/inlay_gen).

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

On the Flutter side, the generated store can be used directly or combined with the optional `InlayCubit` helper.

## Documentation

- [Navigation](https://github.com/leancodepl/inlay/blob/main/docs/navigation.md) - Route definitions, dialogs & bottom sheets, cross-boundary navigation, go_router & auto_route integration
- [State Management](https://github.com/leancodepl/inlay/blob/main/docs/state.md) - Stores, native access, optional Cubit integration, cross-engine sync
- [Testing](https://github.com/leancodepl/inlay/blob/main/docs/testing.md) - Widget-testing screens that navigate and use stores, via `package:inlay/testing.dart` fakes
- [Example apps](https://github.com/leancodepl/inlay/tree/main/example) - A complete Flutter module plus native iOS and Android host apps exercising every feature
- [Agent skills](https://github.com/leancodepl/inlay/tree/main/skills) - Installable skills that teach AI coding agents (Claude Code, Cursor, Codex, …) how to set up inlay, evolve schemas, and test inlay screens

---

## 🛠️ Maintained by LeanCode

<div align="center">
  <a href="https://leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=inlay">
    <img src="https://leancodepublic.blob.core.windows.net/public/wide.png" alt="LeanCode Logo" height="100" />
  </a>
</div>

This package is built with 💙 by **[LeanCode](https://leancode.co?utm_source=github.com&utm_medium=referral&utm_campaign=inlay)**.
We are **top-tier experts** focused on Flutter Enterprise solutions.

### Why LeanCode?

- **Creators of [Patrol](https://patrol.leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=inlay)** – the next-gen testing framework for Flutter.

- **Production-Ready** – We use this package in apps with millions of users.
- **Full-Cycle Product Development** – We take your product from scratch to long-term maintenance.

<div align="center">
  <br />

**Need help with your Flutter project?**

[**👉 Hire our team**](https://leancode.co/get-estimate?utm_source=github.com&utm_medium=referral&utm_campaign=inlay)
&nbsp;&nbsp;•&nbsp;&nbsp;
[Check our other packages](https://pub.dev/packages?q=publisher%3Aleancode.co&sort=downloads)

</div>
