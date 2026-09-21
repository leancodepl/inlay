# inlay_gen

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
[![inlay_gen pub.dev badge](https://img.shields.io/pub/v/inlay_gen)](https://pub.dev/packages/inlay_gen)

Code generator for the [inlay](https://pub.dev/packages/inlay) add-to-app framework. It reads annotated Dart schema files and produces **type-safe route and store classes for Dart, Kotlin, and Swift** (plus Java routes for Android hosts written in Java), so navigation and shared state never rely on arbitrary strings crossing the platform boundary.

## How it works

1. You write plain Dart schema files (specs only - never imported by app code) annotated with inlay annotations.
2. `inlay_gen` parses them and generates matching typed classes for every configured language.
3. The generated Dart compiles into your Flutter module; the generated Kotlin (or Java) and Swift compile into the native hosts.
4. A **schema fingerprint** is embedded in every language's output, so a module and a host built from different schema revisions fail loudly instead of silently corrupting data.

## Annotations

```dart
// A Flutter screen reachable from native or other Flutter screens.
// Declare `result:` to get typed result plumbing (pushForResult / popWithResult).
@InlayFlutterRoute('/counter', result: int)
class CounterPage {
  const CounterPage({this.seed});
  final int? seed;
}

// A Flutter dialog rendered over a native screen in a transparent container.
@InlayFlutterDialog('/confirm-delete/:itemId', result: bool)
class ConfirmDeleteDialog {
  const ConfirmDeleteDialog({required this.itemId});
  final String itemId;
}

// A native screen reachable from Flutter.
@InlayNativeRoute(result: String)
class NativeAboutPage {
  const NativeAboutPage({required this.appVersion});
  final String appVersion;
}

// A typed store on top of inlay's cross-engine key-value storage.
@InlayStore(key: 'user_preferences')
class UserPreferencesStore {
  const UserPreferencesStore({
    @InlayStoreKey() required this.userId, // scopes the store per key
    this.darkMode = false,
    this.tags = const [],
  });

  final String userId;
  final bool darkMode;
  final List<String> tags;
}
```

Supported field types: `bool`, `int`, `double`, `num`, `String`, `Uint8List`, enums, annotated data classes, `List<T>`, `Map<K, V>`, and nested combinations.

## Configuration (`inlay.yaml`)

Place an `inlay.yaml` in your Flutter module:

```yaml
routes: lib/inlay/routes.dart
stores: lib/inlay/stores.dart

dart:
  output: lib/src/generated/

kotlin:
  output: native/android/src/main/kotlin/com/example/generated/
  package: com.example.generated

# Optional - for an Android host written in Java instead of Kotlin.
java:
  output: native/android/src/main/java/com/example/generated/
  package: com.example.generated

swift:
  output: native/ios/native/Sources/native/Generated/
  # Optional in every language section: comment lines emitted at the top of
  # each generated file - lint suppressions, a license notice, etc.
  header:
    - swiftlint:disable all
```

Every section is optional; a language without a section is skipped. `header:` takes a list of
lines (or one multi-line string) and writes each as a `//` comment before the generated-code
banner - the place for lint suppressions such as Checkstyle's `CHECKSTYLE.OFF: ...` in Java or
`ignore_for_file:` in Dart, since generated code is not meant to satisfy hand-written-code rules.

## Running

As a standalone CLI:

```sh
dart run inlay_gen:inlay_gen --config inlay.yaml
```

Or as a `build_runner` builder:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The builder writes the Dart outputs through build_runner's asset graph and runs before
`go_router_builder` / `auto_route_generator`, so router code that imports the generated route
classes resolves them within the same build. `--delete-conflicting-outputs` lets build_runner take
over generated files that are already checked in.

## Outputs

- **Dart** - sealed `FlutterRoute` / `FlutterDialogRoute` hierarchies for exhaustive pattern matching, per-route `encode`/`decode`, typed result helpers, native route wrappers, typed store classes with immutable snapshots and `copyWith`.
- **Kotlin** - route data classes, an abstract `NativeRouteHandler` with typed `on*` methods, typed store wrappers with `containsChanges`.
- **Java** - one file per class: final route classes implementing `FlutterRoute` / `FlutterRouteWithResult<R>`, enums, data classes, `InlaySchema` (fingerprint) and an abstract `NativeRouteHandler` whose result-typed methods take a `java.util.function.Consumer<R>` completion. Routes only - stores are not generated for Java yet.
- **Swift** - route structs conforming to `FlutterRoute`/`FlutterDialogRoute` (with `= nil` defaults for optional fields), a `NativeRouteHandler` class, typed store structs with `containsChanges(in:)`.

See the [inlay documentation](https://github.com/leancodepl/inlay/blob/main/docs/navigation.md) for how the generated code is used, and the [example module](https://github.com/leancodepl/inlay/tree/main/example/example_module) for a complete schema.

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
