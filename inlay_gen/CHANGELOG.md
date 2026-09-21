# 0.2.0

- Java output for Android hosts written in Java - routes, enums, data classes and the
  `NativeRouteHandler` base class. Enable it with a `java:` section in `inlay.yaml`. Stores are
  not supported yet.
- New `header:` option in every language section - adds custom comment lines at the top of
  generated files (lint suppressions, license notices).
- Swift structs with optional fields can now be created without passing every field.
- Fixed generated Dart, Kotlin and Swift code not compiling for routes without fields.
- Generated Dart files are now skipped by `dart format`, so they no longer churn.
- build_runner: generated routes are now available to `go_router_builder` and
  `auto_route_generator` in the same build.

# 0.1.1

- Documentation and example improvements

# 0.1.0

- Initial release
- Generates type-safe route classes for Dart, Kotlin, and Swift from `@InlayFlutterRoute`, `@InlayFlutterDialog`, and `@InlayNativeRoute` annotations
- Generates typed store wrappers and immutable snapshots from `@InlayStore` / `@InlayStoreKey` schemas
- Typed result plumbing (`pushForResult`, `popWithResult`, `encodeResult` / `decodeResult`) for routes declaring `result:`
- Schema fingerprint embedded in all three languages for automatic drift detection
- Works as a build_runner builder and as a standalone CLI (`dart run inlay_gen:inlay_gen`)
