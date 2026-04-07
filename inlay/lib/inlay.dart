/// Cross-platform inlay framework for Flutter.
///
/// Provides:
/// - `InlayNavigator` — push/pop Flutter pages from Dart and native code.
/// - `InlayFlutterRoute` — base class for typed Flutter route definitions.
/// - `KeyValueStorage` — shared key-value storage with cross-engine sync.
/// - `InlayCubit` — Cubit base class backed by cross-platform stores.
/// - Annotations for code generation (`@FlutterRoute`, `@NativeRoute`, `@Store`)
/// - Router integrations for go_router, auto_route, and Navigator 2.0.
library;

export 'src/annotations.dart';
export 'src/cubit/inlay_cubit.dart';
export 'src/cubit/inlay_state.dart';
export 'src/cubit/inlay_store_observer.dart';
export 'src/navigator/inlay_back_button_dispatcher.dart';
export 'src/navigator/inlay_dialog.dart';
export 'src/navigator/inlay_native_pop_gesture_observer.dart';
export 'src/navigator/inlay_navigator.dart';
export 'src/navigator/integrations/navigator2_integration.dart';
export 'src/storage/inlay_snapshot_store.dart';
export 'src/storage/key_value_storage.dart';
