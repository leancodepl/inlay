# 0.2.0

- Java output: `java:` section in `inlay.yaml` (or `--java-output` / `--java-package`) generates
  route classes, enums, data classes and the `NativeRouteHandler` base class as plain Java for
  Android hosts written in Java. One file per class, with the schema fingerprint in
  `InlaySchema` and typed results (`FlutterRouteWithResult` / `FlutterDialogRouteWithResult`,
  `encodeResult` / `decodeResult`). Stale generated Java files are removed on regeneration.
  Stores are not generated for Java yet.
- `header:` in every language section of `inlay.yaml` - comment lines emitted at the top of each
  generated file (lint suppressions, license notice), the same idea as pigeon's `copyrightHeader`.
- Swift route and data structs with optional fields get a memberwise `init` with `= nil`
  defaults, so callers can omit them.
- Kotlin: routes without fields are generated as plain classes - `data class` requires at least
  one constructor parameter, so they did not compile.
- Dart: routes and data classes without fields no longer produce `encode() => <Object?>[];;`,
  which did not parse.
- Swift: `toDict()` of routes without URL parameters returns `[:]` instead of the array literal
  `[]`, which did not compile.
- Generated Dart files start with `// dart format off`: they are exempt from `dart format` (and
  from `--set-exit-if-changed` checks), so no formatting pass is needed after generation and
  regenerating or bumping the SDK does not churn them.
- build_runner: the Dart outputs are written through the build step (asset graph) and the builder
  is ordered before `go_router_builder` / `auto_route_generator`, so router code that imports the
  generated route classes resolves them within the same build. Run with
  `--delete-conflicting-outputs` when the generated files are checked in.

# 0.1.1

- Documentation and example improvements

# 0.1.0

- Initial release
- Generates type-safe route classes for Dart, Kotlin, and Swift from `@InlayFlutterRoute`, `@InlayFlutterDialog`, and `@InlayNativeRoute` annotations
- Generates typed store wrappers and immutable snapshots from `@InlayStore` / `@InlayStoreKey` schemas
- Typed result plumbing (`pushForResult`, `popWithResult`, `encodeResult` / `decodeResult`) for routes declaring `result:`
- Schema fingerprint embedded in all three languages for automatic drift detection
- Works as a build_runner builder and as a standalone CLI (`dart run inlay_gen:inlay_gen`)
