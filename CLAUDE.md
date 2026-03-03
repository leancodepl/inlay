# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**leancode_add2app** — an opinionated Flutter add-to-app framework providing type-safe navigation and cross-platform state sharing. Uses a multi-engine approach (FlutterEngineGroup) with engine management hidden from the end user.

## Workspace Structure

Dart workspace (SDK ^3.11.0) with four packages:

| Package | Role |
|---------|------|
| `leancode_add2app/` | Core framework plugin (Dart + Swift + Kotlin). Navigation, storage, platform channels via Pigeon. |
| `leancode_add2app_gen/` | Code generator — produces typed route/store classes for Dart, Kotlin, Swift from annotated schemas. |
| `signal_module/` | Flutter module embedded in Signal app forks (real-world benchmark). |
| `example/example_module/` | Standalone example Flutter module with go_router, auto_route, and sealed-class routing demos. |

Non-workspace directories: `example/example_android/`, `example/example_ios/` (native host apps), `Signal-iOS/`, `Signal-Android/` (Signal app forks).

## Common Commands

```bash
# Dependencies (run from repo root — workspace resolves all packages)
dart pub get

# Code generation (run from signal_module/ or example/example_module/)
dart run build_runner build

# CLI alternative for code generation
dart run leancode_add2app_gen:leancode_add2app_gen --config add2app.yaml

# Pigeon generation (run from leancode_add2app/)
dart run pigeon --input pigeons/add2app_navigator.dart
dart run pigeon --input pigeons/key_value_storage.dart

# Lint
dart analyze

# Format
dart format .

# Tests (run from leancode_add2app_gen/)
dart test
# Single test:
dart test test/annotation_parser_test.dart
```

## Architecture

### Code Generation Pipeline

1. **Input:** Annotated Dart schema files (`@Add2AppFlutterRoute`, `@Add2AppNativeRoute`, `@Add2AppStore`) — these are specs only, not imported by app code.
2. **Processing:** `leancode_add2app_gen` parses annotations via `analyzer`, produces typed classes.
3. **Output:** `routes.g.dart`, `stores.g.dart` (Dart) + equivalent Kotlin data classes and Swift structs.
4. **Config:** `add2app.yaml` in each module specifies schema paths and output directories per language.
5. **Integration:** Works as both a `build_runner` builder and a standalone CLI.

### Platform Channels (Pigeon)

Two pigeon definitions in `leancode_add2app/pigeons/`:
- `add2app_navigator.dart` — navigation APIs (push/pop between native and Flutter)
- `key_value_storage.dart` — cross-engine key-value storage sync

Generated outputs go to `lib/src/*/...g.dart`, `android/src/.../...Api.g.kt`, `ios/Classes/...Api.g.swift`.

### Navigation

- Each Flutter screen runs in its own engine (created/destroyed automatically).
- Single Dart entrypoint (`add2appMain`) handles all engines.
- Three routing integration patterns in examples: go_router (declarative), auto_route (declarative), sealed classes + pattern matching (imperative).
- `Add2AppBackButtonDispatcher` and `Add2AppNativePopGestureObserver` handle back gesture/pop coordination between native and Flutter navigation stacks.

### Cross-Engine State (KeyValueStorage)

- In-memory dictionary on the platform side, synced to all Flutter engines and native scopes in real-time.
- Every read/write goes through the platform channel (no local Dart cache).
- Writers don't receive their own change notifications (self-notification suppression).
- Optional `Add2AppCubit` helper for reactive BLoC integration.

## Development Rules

- **Always consider both iOS and Android.** Do not add support for only one platform unless explicitly instructed.
- **All cross-platform APIs must be type-safe.** Never pass arbitrary strings or dynamic data.
- **Breaking changes are OK.** The framework is in PoC state and not published yet — no backwards compatibility needed.
- **Thread safety matters.** Always verify solutions work with multiple Dart isolates and check for race conditions.
- **After changing Dart code:** run `dart analyze` then `dart format .`.
- **Signal forks:** prefer modifying existing native screens over adding new ones — this better validates framework usability.
- **Linting:** all packages use `leancode_lint` (analysis_options.yaml includes `package:leancode_lint/analysis_options_package.yaml`).
