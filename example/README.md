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

The iOS host integrates the Flutter module through Swift Package Manager (Flutter 3.44+).
Build the module's Swift package first, then generate and open the Xcode project:

```bash
cd example/example_module
flutter build swift-package --platform ios

cd ../example_ios
xcodegen generate
open ExampleApp.xcodeproj
```

Re-run `flutter build swift-package` whenever the module's dependencies change (Dart code
changes are rebuilt by Xcode automatically). To build from the command line:

```bash
xcodebuild build -project ExampleApp.xcodeproj -scheme ExampleApp \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```
