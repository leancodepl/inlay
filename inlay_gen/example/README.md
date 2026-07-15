# inlay_gen example

Generating type-safe route and store classes for Dart, Kotlin, and Swift from a
Dart schema. For a complete schema and its generated output see the
[example module](https://github.com/leancodepl/inlay/tree/main/example/example_module).

## 1. Write a schema (specs only — never imported by app code)

```dart
// A Flutter screen reachable from native or other Flutter screens.
// `result:` adds typed result plumbing (pushForResult / popWithResult).
@InlayFlutterRoute('/counter', result: int)
class CounterPage {
  const CounterPage({this.seed});
  final int? seed;
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
  });

  final String userId;
  final bool darkMode;
}
```

## 2. Configure `inlay.yaml`

```yaml
routes: lib/inlay/routes.dart
stores: lib/inlay/stores.dart

dart:
  output: lib/src/generated/

kotlin:
  output: native/android/src/main/kotlin/com/example/generated/
  package: com.example.generated

swift:
  output: native/ios/Classes/Generated/
```

## 3. Generate

As a standalone CLI:

```sh
dart run inlay_gen:inlay_gen --config inlay.yaml
```

Or as a `build_runner` builder:

```sh
dart run build_runner build
```

This produces matching typed classes for all three languages, each embedding a
schema fingerprint so a module and a host built from different schema revisions
fail loudly instead of silently corrupting data.
