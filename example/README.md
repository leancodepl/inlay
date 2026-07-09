# Example Apps

This folder contains a standalone showcase for the Inlay framework:

- `example_module` - Flutter module with routes, stores, cubits, and three integrations:
  - go_router
  - auto_route
  - Imperative via sealed class pattern matching (`fetchInitialRoute` / `decodeFlutterRouteData`)
- `example_android` - Native Android host app (Activity + Fragment + Compose demos)
- `example_ios` - Native iOS host app (UIKit + SwiftUI demos)

Both hosts expose framework-level controls on their native settings screens: switch the routing integration (go_router / auto_route / imperative) at runtime and toggle engine prewarming. End-to-end UI test suites live in `example_ios/UITests` (XCUITest) and `example_android/app/src/androidTest` (UiAutomator).

## Flutter module setup

```bash
cd example/example_module
dart run build_runner build
```

## Android setup

```bash
cd example/example_android
./gradlew :app:assembleDebug
```

## iOS setup

```bash
cd example/example_ios
xcodegen generate
pod install
```
