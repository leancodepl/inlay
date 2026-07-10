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
