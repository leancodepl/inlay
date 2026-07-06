/// Test doubles for inlay.
///
/// Import in widget/unit tests only:
///
/// ```dart
/// import 'package:inlay/testing.dart';
///
/// setUp(() {
///   KeyValueStorage.instance = FakeKeyValueStorage();
///   InlayNavigator.instance = FakeInlayNavigator();
/// });
/// ```
///
/// The fakes involve no platform channels, so screens that navigate or
/// read/write stores can be tested with plain `testWidgets`.
library;

export 'src/testing/fake_inlay_navigator.dart';
export 'src/testing/fake_key_value_storage.dart';
