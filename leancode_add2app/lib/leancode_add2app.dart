/// Cross-platform add2app framework for Flutter.
///
/// Provides:
/// - `Add2AppNavigator` — push/pop Flutter pages from Dart and native code.
/// - `Add2AppFlutterRoute` — base class for typed Flutter route definitions.
/// - `KeyValueStorage` — shared key-value storage with cross-engine sync.
/// - Annotations for code generation (`@FlutterRoute`, `@NativeRoute`, `@Store`)
library;

export 'src/annotations.dart';
export 'src/navigator/add2app_navigator.dart';
export 'src/storage/key_value_storage.dart';
