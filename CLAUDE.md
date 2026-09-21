# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**inlay** — an opinionated Flutter add-to-app framework providing type-safe navigation and cross-platform state sharing. Uses a multi-engine approach (FlutterEngineGroup) with engine management hidden from the end user.

## Workspace Structure

Dart workspace (SDK ^3.11.0) with five packages:

| Package                                          | Role                                                                                                |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| `inlay/`                                         | Core framework plugin (Dart + Swift + Kotlin). Navigation, storage, platform channels via Pigeon.   |
| `inlay_compose/`                                 | Optional Jetpack Compose integration (Android-only) for embedding inlay screens in Compose hosts.   |
| `inlay_gen/`                                     | Code generator — produces typed route/store classes for Dart, Kotlin, Swift (and Java routes) from annotated schemas. |
| `example/example_module/`                        | Standalone example Flutter module with go_router, auto_route, and sealed-class routing demos.       |
| `example/example_module/example_module_native/`  | Companion plugin holding the module's generated native code so `flutter build aar` bundles it.      |

Non-workspace directories: `example/example_android/`, `example/example_ios/` (native host apps), `docs/` (internal library docs in Markdown).

## Common Commands

```bash
# Dependencies (run from repo root — workspace resolves all packages)
dart pub get

# Code generation (run from example/example_module/)
dart run build_runner build --delete-conflicting-outputs

# CLI alternative for code generation
dart run inlay_gen:inlay_gen --config inlay.yaml

# Pigeon generation (run from inlay/)
# Use the script — it runs pigeon + patches Swift with `public` modifiers:
./generate_pigeon.sh

# Lint
dart analyze

# Format
dart format .

# Tests (run from inlay_gen/)
dart test
# Single test:
dart test test/annotation_parser_test.dart

# Native example apps
# Android (from example/example_android/):
./gradlew :app:assembleDebug
# iOS - SwiftPM integration: build the module's Swift package first
# (from example/example_module/), then the host (from example/example_ios/):
flutter build swift-package --platform ios
xcodebuild build -project ExampleApp.xcodeproj -scheme ExampleApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

## Architecture

### Code Generation Pipeline

1. **Input:** Annotated Dart schema files (`@InlayFlutterRoute`, `@InlayNativeRoute`, `@InlayStore`) — these are specs only, not imported by app code.
2. **Processing:** `inlay_gen` parses annotations via `analyzer`, produces typed classes.
3. **Output:** `routes.g.dart`, `stores.g.dart` (Dart) + equivalent Kotlin data classes and Swift structs; optionally Java route classes (one file per class) for Android hosts written in Java.
4. **Config:** `inlay.yaml` in each module specifies schema paths and output directories per language; every language section is optional.
5. **Integration:** Works as both a `build_runner` builder and a standalone CLI. The builder writes Dart outputs through the build step and is ordered before `go_router_builder` / `auto_route_generator`, so those can import the generated route classes in the same build.

### Platform Channels (Pigeon)

Two pigeon definitions in `inlay/pigeons/`:

- `inlay_navigator.dart` — navigation APIs (push/pop between native and Flutter)
- `key_value_storage.dart` — cross-engine key-value storage sync

Generated outputs go to `lib/src/*/...g.dart`, `android/src/.../...Api.g.kt`, `ios/inlay/Sources/inlay/...Api.g.swift`.

**Important:** Pigeon does not generate `public` Swift types, but the plugin module boundary requires it. Use `./generate_pigeon.sh` (in `inlay/`) instead of running `dart run pigeon` directly — the script runs pigeon and then patches Swift output with the necessary `public` access modifiers.

### Navigation

- Each Flutter screen runs in its own engine (created/destroyed automatically).
- Single Dart entrypoint (`inlayMain`) handles all engines.
- Three routing integration patterns in examples: go_router (declarative), auto_route (declarative), sealed classes + pattern matching (imperative).
- iOS plugins (`inlay`, `example_module_native`) ship both `Package.swift` (Flutter SwiftPM layout: `ios/<plugin>/Sources/<plugin>/`) and a podspec pointing at the same sources - keep both in sync when adding Swift files. The iOS example host integrates via SwiftPM (`flutter build swift-package`), not CocoaPods; the generated Swift stays internal to the plugin, so the host compiles the `Generated` directory into its own target.
- `InlayBackButtonDispatcher` and `InlayNativePopGestureObserver` handle back gesture/pop coordination between native and Flutter navigation stacks.

### Cross-Engine State (KeyValueStorage)

- In-memory dictionary on the platform side, synced to all Flutter engines and native scopes in real-time.
- Every read/write goes through the platform channel (no local Dart cache).
- Writers don't receive their own change notifications (self-notification suppression).
- Optional `InlayCubit` helper for reactive BLoC integration.

## Development Rules

- **Always consider both iOS and Android.** Do not add support for only one platform unless explicitly instructed.
- **All cross-platform APIs must be type-safe.** Never pass arbitrary strings or dynamic data.
- **Breaking changes are OK.** The framework is not published yet — no backwards compatibility needed.
- **Thread safety matters.** Always verify solutions work with multiple Dart isolates and check for race conditions.
- **After changing Dart code:** run `dart analyze` then `dart format .`.
- **Linting:** all packages use `leancode_lint` (analysis_options.yaml includes `package:leancode_lint/analysis_options_package.yaml`).
- **Feature independence:** future plan involves splitting the current framework into separate packages so that features (navigation, stores, BLoC integration) can be used separately. Do not introduce cross-feature dependencies that will be hard to resolve later.
- **Example:** any new feature added to the framework should have a use case added to the main example in `example` folder. Always consider example in the plan mode. Prefer expanding existing pages over adding new pages and complicating the example if possible.
- **Docs:** after introducing any changes inspect the `docs` folder and `README.md` and introduce any updates if necessary. `README.md` is supposed to be a general overview and shouldn't include too many details. Prefer directing the reader to detailed docs in the `docs` folder.
- **Agent skills:** `skills/` contains end-user Agent Skills (`inlay-setup`, `inlay-add-route`, `inlay-testing`) distributed via the `skills` CLI. When behavior they cover changes — integration/setup steps, annotations, codegen config or commands, router wiring, testing fakes — update the matching `skills/*/SKILL.md` (and its doc links) too.
- **Native code verification:**: After introducing any changes in the generator or the native code, always compile native example iOS and Android applications before completion.
