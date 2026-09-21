---
name: inlay-add-route
description: Add or change inlay routes, dialogs, and shared stores in a Flutter add-to-app module — edit the annotated Dart schema, regenerate Dart/Kotlin/Java/Swift, and wire both the Flutter and native sides. Use when adding a Flutter screen or dialog reachable from native, a native screen reachable from Flutter, or state shared between native and Flutter, in a project that already uses inlay.
---

# Add an inlay route, dialog, or store

The recurring inlay workflow: schema → codegen → wire Dart side → wire native side. Canonical
docs are the source of truth for the code at each step:

- **Routes, dialogs, navigation, results** —
  https://github.com/leancodepl/inlay/blob/main/docs/navigation.md
- **Stores and shared state** — https://github.com/leancodepl/inlay/blob/main/docs/state.md
- **Complete reference schema and wiring** —
  https://github.com/leancodepl/inlay/tree/main/example/example_module

Everything crossing the platform boundary is typed — never pass strings or maps where a
generated class exists.

## 1. Edit the schema

Schema files are the plain annotated Dart classes listed in the module's `inlay.yaml`
(`routes:` / `stores:`). Pick the annotation:

| You're adding | Annotation | Notes |
|---|---|---|
| Flutter screen | `@InlayFlutterRoute('/path/:param')` | Path params (`:param`) map to required fields; other fields travel as extra data. |
| Flutter dialog / bottom sheet over a native screen | `@InlayFlutterDialog('/path/:param')` | Same rules as routes; presented in a transparent native container. |
| Native screen callable from Flutter | `@InlayNativeRoute()` | Fields become the typed payload. |
| Shared state | `@InlayStore(key: 'prefix')` + `@InlayStoreKey()` on scoping fields | Value fields: primitives, enums, `List`/`Map`/data classes. Non-nullable complex fields need a default. |

A screen that returns a value to its caller declares `result:` on the annotation (e.g.
`@InlayFlutterDialog('/confirm/:id', result: bool)`) — this generates typed result plumbing on
both sides. See
https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#returning-results-from-screens

## 2. Regenerate

From the module root:

```bash
dart run build_runner build --delete-conflicting-outputs
# or: dart run inlay_gen:inlay_gen --config inlay.yaml
```

This rewrites the Dart output **and** the Kotlin/Java/Swift outputs configured in `inlay.yaml`
(the Java output is one file per class; files for removed routes are deleted). Never edit
`*.g.dart` / `*.g.kt` / `*.g.swift` or the generated `*.java` by hand. The Dart output starts
with `// dart format off`, so it needs no formatting pass and `dart format --set-exit-if-changed`
leaves it alone.

## 3. Wire the Flutter side

- **Flutter route/dialog** — register the path with whichever integration the entrypoint uses
  (check the module's `inlayMain`):
  - go_router: a `GoRoute` for the path; dialogs use `pageBuilder` with `InlayDialogPage` /
    `InlayBottomSheetPage` —
    https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#go_router-example
  - auto_route: a `NamedRouteDef`; dialogs use `InlayDialogLauncher` inside a transparent
    zero-transition route —
    https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#auto_route-example
  - imperative: add a `case` to the `switch` over the sealed route — the compiler forces this
    (non-exhaustive switch error) —
    https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#imperative-sealed-class--pattern-matching
- **Native route** — Flutter calls it via
  `InlayNavigator.instance.push(MyNativePage(...).toNativeRoute())`; nothing else Dart-side.
- **Store** — instantiate the generated store with `KeyValueStorage.instance`, or pair it with
  `InlayCubit` — https://github.com/leancodepl/inlay/blob/main/docs/state.md#using-stores-from-flutter-dart

## 4. Wire the native side

Do **both** platforms the project has:

- **Flutter route/dialog** — call it where needed: `InlayNavigator.shared.push/present(Dialog)`
  (Swift), `InlayNavigator.push/presentDialog/createFragment` (Kotlin;
  `InlayNavigator.INSTANCE.…` from Java), `InlayFlutterView` /
  `.inlayDialog` (SwiftUI), `InlayFlutterScreen` / `InlayFlutterDialog` (Compose, needs
  `inlay_compose`) — https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#navigating
- **Native route** — the regenerated `NativeRouteHandler` base class gains a typed `on<Name>`
  method; implement it in each host's handler (routes with `result:` also get a `completion`
  callback to invoke - a `Consumer<R>` in the Java output) —
  https://github.com/leancodepl/inlay/blob/main/docs/navigation.md#handling-native-routes-flutter--native
- **Store** — construct the generated wrapper over a `NativeStorageScope`; observe with
  `startObserving` + `containsChanges` —
  https://github.com/leancodepl/inlay/blob/main/docs/state.md#using-stores-from-native-code

## 5. Verify

1. `dart analyze` in the module — the imperative integration surfaces missed routes as
   non-exhaustive `switch` errors here.
2. **Rebuild both native hosts.** Generated code embeds a schema fingerprint; a host built from
   pre-change Kotlin/Swift fails at navigation time with `InlaySchemaMismatchException`
   (Dart) / `IllegalStateException` (Android) / `fatalError` (iOS) rather than corrupting data.
   A schema change is not done until the hosts compile against the regenerated code.
3. Exercise the new route/store once end-to-end on each platform if a device/simulator is
   available.

## Gotchas

- The Kotlin/Swift outputs live in the module's **companion native plugin** (see `inlay.yaml`)
  — if new generated files aren't picked up by the iOS host, check they're inside the
  directory the app target/podspec already compiles.
- Dialog engines need a transparent background: go_router setups switch
  `scaffoldBackgroundColor` to transparent when the initial route is a dialog; `runInlayDialog`
  handles it in the imperative setup.
- Store writes don't notify the writer (self-notification suppression) — don't wait for your
  own change on `stream`.
