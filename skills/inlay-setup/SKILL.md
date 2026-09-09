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
  output: <module>_native/ios/<module>_native/Sources/<module>_native/Generated/
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
`inlay`), stub plugin classes, an Android library `build.gradle.kts`, and on iOS **both**
integration manifests: `ios/<module>_native/Package.swift` (Swift Package Manager - depends on
`../FlutterFramework` and `../inlay`, product name with `-` instead of `_`) and
`ios/<module>_native.podspec` (CocoaPods - `s.source_files` pointing at
`<module>_native/Sources/<module>_native/**/*.swift`, `s.dependency 'inlay'`). Without the
`Package.swift` the plugin is built as a CocoaPods xcframework instead of a Swift package. Add
the plugin to the module's `dependencies` by path.

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

1. Integrate the module. Prefer **Swift Package Manager** (Flutter 3.44+, Xcode 15+); use
   CocoaPods only if the host already depends on it (Flutter keeps CocoaPods in maintenance
   mode and its registry goes read-only on 2 December 2026). Follow
   https://docs.flutter.dev/add-to-app/ios/project-setup exactly:
   - **SwiftPM:** in the module run `flutter build swift-package --platform ios`. In Xcode add
     the generated `<module>/build/ios/SwiftPackages/FlutterNativeIntegration` package
     (reference in place) and link `FlutterNativeIntegration`; set the
     `FLUTTER_SWIFT_PACKAGE_OUTPUT` build setting to `$(SRCROOT)/<path>/build/ios/SwiftPackages`;
     add a scheme **Build pre-action** `/bin/sh $FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh prebuild`
     (build settings from the app target) and a **Run Script build phase**
     `/bin/sh $FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh assemble` with
     input file list `$(FLUTTER_SWIFT_PACKAGE_OUTPUT)/Scripts/FlutterAssembleInputs.xcfilelist`
     and "Based on dependency analysis" off. Optionally set `FLUTTER_APPLICATION_PATH` and
     `ENABLE_USER_SCRIPT_SANDBOXING=NO` so Xcode rebuilds Dart changes. The example's XcodeGen
     `project.yml` encodes all of this.
   - **CocoaPods:** `Podfile` loads the module's `podhelper.rb`, calls
     `install_all_flutter_pods(flutter_application_path)` and `flutter_post_install(installer)`
     in `post_install`; then `pod install`.
2. Add the generated Swift directory
   (`<module>_native/ios/<module>_native/Sources/<module>_native/Generated`) to the **app
   target's sources** so host code can use the typed routes/stores - the generated types are
   internal to the plugin module (the example does this in its XcodeGen `project.yml`).
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
- **`build/ios/SwiftPackages` is generated too.** A missing `FlutterNativeIntegration` package
  means `flutter build swift-package --platform ios` hasn't run. Re-run it after adding or
  removing module dependencies (Dart-only changes rebuild from Xcode). As of Flutter 3.44 the
  command still runs `pod install` for a module and builds every plugin as a pod first
  (flutter/flutter#184590), so CocoaPods must be installed even for a SwiftPM host. If a
  plugin's podspec paths change or it gains a `Package.swift`, delete the module's `.ios/Pods`,
  `.ios/Podfile.lock` and `build/ios/SwiftPackages` first — the stale Pods project fails with
  "Build input files cannot be found", and the cached CocoaPods framework otherwise conflicts
  with the new Swift package ("multiple packages declare targets with a conflicting name").
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
