/// Cross-platform add2app framework for Flutter.
///
/// Provides:
/// - [Add2AppNavigator] — push/pop Flutter pages from Dart and native code.
/// - [Add2AppFlutterRoute] — base class for typed Flutter route definitions.
/// - [KeyValueStorage] — shared key-value storage with cross-engine sync.
/// - [add2appMain] — bootstrap function for the unified Dart entrypoint.
library;

export 'src/navigator/add2app_navigator.dart'
    show
        Add2AppNavigator,
        Add2AppNativeRoute,
        Add2AppFlutterRoute,
        Add2AppRoute,
        Add2AppRouteType,
        PageBuilder,
        PageSettings;
export 'src/storage/key_value_storage.dart' show KeyValueStorage, StorageEntry;
