# 0.1.0

- Initial release
- Generates type-safe route classes for Dart, Kotlin, and Swift from `@InlayFlutterRoute`, `@InlayFlutterDialog`, and `@InlayNativeRoute` annotations
- Generates typed store wrappers and immutable snapshots from `@InlayStore` / `@InlayStoreKey` schemas
- Typed result plumbing (`pushForResult`, `popWithResult`, `encodeResult` / `decodeResult`) for routes declaring `result:`
- Schema fingerprint embedded in all three languages for automatic drift detection
- Works as a build_runner builder and as a standalone CLI (`dart run inlay_gen:inlay_gen`)
