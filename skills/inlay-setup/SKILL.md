---
name: inlay-setup
description: Set up inlay (Flutter add-to-app framework) in a project for the first time — Flutter module dependencies, the `inlay.yaml` codegen config, the companion native plugin for generated Kotlin/Swift, and native host wiring on both iOS and Android. Use when adding inlay to a project that does not have it yet.
---

# Inlay setup

Wire an existing native app (iOS, Android, or both) to a Flutter module through inlay, ending
with a Flutter screen opening from native code. This skill is the ordered process and the
gotchas; the canonical docs and the reference example are the source of truth for code — follow
them at each step instead of guessing:

- **Navigation guide** (concepts, setup, router integration) —
  https://github.com/leancodepl/inlay/blob/main/docs/navigation.md
- **Codegen config and annotations** — https://pub.dev/packages/inlay_gen
- **Reference example** (module + native hosts, exercises every feature) —
  https://github.com/leancodepl/inlay/tree/main/example

Set up **every platform the project has**. If both an iOS and an Android host exist, wiring only
one is an incomplete setup — tell the user if you skip a platform and why.

## 1. Survey the project

- Is there already a Flutter **module** (`flutter: module:` in its `pubspec.yaml`)? If not,
  create one with `flutter create --template module <name>`. A plain Flutter *app* cannot be
  embedded — it must be a module.
- Which hosts exist — iOS (UIKit/SwiftUI), Android (Views/Compose)?
- Which Flutter router does the module use (go_router, auto_route, none)? This decides the
  entrypoint style in step 3.

## 2. Module: dependencies and codegen config

In the module's `pubspec.yaml`:

- `dependencies`: `inlay` (and `inlay_compose` **only** if the Android host uses Jetpack
  Compose — it pulls Compose onto the classpath).
- `dev_dependencies`: `inlay_gen`, `build_runner`.

Create `inlay.yaml` next to `pubspec.yaml`. It names the schema files and the per-language
output directories:

```yaml
routes: lib/inlay/routes.dart
stores: lib/inlay/stores.dart

dart:
  output: lib/src/generated/

kotlin:
  output: <module>_native/android/src/main/kotlin/<package path>/generated/
  package: <host package>.generated

swift:
  output: <module>_native/ios/Classes/Generated/
```

Create the schema files: plain Dart classes annotated with `@InlayFlutterRoute('/path/:param')`,
`@InlayFlutterDialog(...)`, `@InlayNativeRoute()`, `@InlayStore(...)`. They are specs only —
app code never imports them. See
https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#defining-routes

**Companion native plugin.** The generated Kotlin/Swift must live in a small Flutter plugin
inside the module (the `<module>_native/` paths above) so `flutter build aar` bundles them into
binary artifacts. Mirror the reference:
https://github.com/leancodepl/inlay/tree/main/example/example_module/example_module_native —
a plugin `pubspec.yaml` (android `package`/`pluginClass`, ios `pluginClass`, dependency on
`inlay`), stub plugin classes, a podspec with `s.source_files = 'Classes/**/*'` and
`s.dependency 'inlay'`, and an Android library `build.gradle.kts`. Add it to the module's
`dependencies` by path.

Then run codegen from the module: `dart run build_runner build` (or
`dart run inlay_gen:inlay_gen --config inlay.yaml`), followed by `dart format` on the Dart
output directory — the generator's raw output is not formatter-clean.

## 3. Module: the Dart entrypoint

Every engine runs one top-level entrypoint, `inlayMain` by default, annotated with
`@pragma('vm:entry-point')`. Its shape depends on the router — copy the matching example:

- go_router — https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#go_router-example
- auto_route — https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#auto_route-example
- no router (sealed-class pattern matching) —
  https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#imperative-sealed-class--pattern-matching

Common to all: `WidgetsFlutterBinding.ensureInitialized()`, then
`await KeyValueStorage.instance.init()`, then resolve the initial route. Declarative setups also
need `backButtonDispatcher: InlayBackButtonDispatcher()` and an `InlayNativePopGestureObserver`
wrapped around the router's child.

## 4. Android host

Follow https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#setup plus the
reference host: https://github.com/leancodepl/inlay/tree/main/example/example_android

1. `settings.gradle(.kts)`: add the `download.flutter.io` maven repo, then include the module
   sources:
   ```kotlin
   include(":app")
   include(":<module>")
   apply(from = File(settingsDir, "<path to module>/.android/include_flutter.groovy"))
   project(":<module>").projectDir = File(settingsDir, "<path to module>")
   ```
2. App `dependencies`: `implementation(project(":flutter"))` and
   `implementation(project(":inlay"))`. The generated Kotlin arrives transitively through the
   companion plugin.
3. `Application.onCreate`: `InlayNavigator.init(applicationContext)` and, if the schema has
   native routes, `InlayNavigator.setNativeRouteHandler(...)`.
4. Any Activity hosting an `InlayFlutterFragment` (including via Compose's
   `InlayFlutterScreen` or dialogs) must forward seven callbacks — extend
   `InlayFlutterHostActivity`, or use `InlayFragmentHostDelegate` from a custom base class:
   https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#host-activity-forwarding

## 5. iOS host

Follow https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#setup plus the
reference host: https://github.com/leancodepl/inlay/tree/main/example/example_ios

1. `Podfile`: load the module's `podhelper.rb` and call
   `install_all_flutter_pods(flutter_application_path)`; add `flutter_post_install(installer)`
   in `post_install`. Then `pod install`.
2. Add the generated Swift directory (`<module>_native/ios/Classes/Generated`) to the **app
   target's sources** so host code can use the typed routes/stores (the example does this in
   its XcodeGen `project.yml`).
3. `AppDelegate`, in this order:
   ```swift
   InlayNavigator.shared.setOnEngineCreated { engine in
       GeneratedPluginRegistrant.register(with: engine)   // import FlutterPluginRegistrant
   }
   InlayNavigator.shared.start()
   InlayNavigator.shared.setNativeRouteHandler(MyNativeRouteHandler())  // if native routes exist
   ```

## 6. Verify

1. From the module: `flutter pub get`, then codegen, then `dart analyze`.
2. Build the Android host (`./gradlew :app:assembleDebug`) and the iOS host (`xcodebuild` or
   Xcode). Both must compile.
3. Add one real navigation call in each host (e.g.
   `InlayNavigator.push(context, SomePage(...))` / `InlayNavigator.shared.push(from:route:)`)
   and confirm the Flutter screen opens on a device or simulator.

## Gotchas

- **`.android` / `.ios` are generated.** They appear only after `flutter pub get` runs in the
  module. Errors like a missing `include_flutter.groovy` or `podhelper.rb` mean pub get hasn't
  run — they are not checked in.
- **iOS plugin registration is manual.** The iOS embedding does not register plugins on
  engines inlay creates — without the `setOnEngineCreated` callback (set **before** `start()`),
  every plugin with native iOS code throws `MissingPluginException`. On Android registration is
  automatic; registering again in `setOnEngineCreated` there **double-registers and is a bug**.
  See https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#plugin-registration-setonenginecreated
- **Regenerate all languages together.** Generated code embeds a schema fingerprint; a host
  built from stale Kotlin/Swift fails loudly at navigation time
  (`InlaySchemaMismatchException`). After any schema change, rerun codegen and rebuild the
  hosts. See https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#schema-fingerprint-automatic-drift-detection
- **Compose dialogs:** never wrap `InlayFlutterDialog` in a Compose `Dialog` or a Navigation
  `dialog()` destination — a `FragmentManager` cannot attach fragments inside a Compose dialog
  window. Use it directly, driven by state.
