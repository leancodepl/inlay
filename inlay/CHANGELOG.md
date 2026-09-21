# 0.2.0

- Android: `InlayNavigator.ensureInitialized(context)` re-registers the engine group; called
  automatically by `InlayFlutterActivity` and `InlayFlutterFragment`, so containers restored after
  process death no longer crash with `IllegalStateException` when the app initializes inlay lazily
  instead of in `Application.onCreate`.
- Android: route data for fragments and dialogs is stored in the fragment arguments instead of an
  in-memory map, so a container restored after process death still receives its full typed route
  (non-path parameters included).
- iOS: the engine is torn down (`destroyContext`) when its container is deallocated, instead of
  lingering until the last reference to it goes away.
- iOS: `Package.swift` declares the `FlutterFramework` dependency explicitly, like the Flutter
  plugin template, so `flutter build swift-package` no longer injects it with
  `swift package add-dependency` - which fails on SwiftPM versions that validate the path.

# 0.1.1

- iOS plugin now supports Swift Package Manager alongside CocoaPods
- Relaxed `meta` constraint to `^1.16.0` for wider Flutter SDK compatibility

# 0.1.0

- Initial release
- Type-safe navigation between native and Flutter screens in both directions, with typed screen results delivered as already-decoded values (`FlutterRouteWithResult` / `FlutterDialogRouteWithResult`)
- Multi-engine management on top of `FlutterEngineGroup` with automatic engine lifecycle, optional prewarming, and a configurable Dart entrypoint
- Cross-engine key-value storage synchronized in real time between Flutter isolates and native code, with typed store wrappers and optional `InlayCubit` BLoC integration
- Cross-engine theme and locale propagation (`InlayAppearance`)
- Dialog and bottom-sheet routes in transparent native containers, integrating with go_router, auto_route, and imperative routing
- SwiftUI embeddings (`InlayFlutterView`, `.inlayDialog`) and Android Fragment hosting; Jetpack Compose support via the separate `inlay_compose` package
- Automatic schema-drift detection via a generated schema fingerprint
- In-memory fakes for widget testing (`package:inlay/testing.dart`)
