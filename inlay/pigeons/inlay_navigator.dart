import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/navigator/inlay_navigator.g.dart',
    kotlinOut:
        'android/src/main/kotlin/co/leancode/inlay/navigator/InlayNavigatorApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'co.leancode.inlay.navigator',
      errorClassName: 'InlayNavigatorError',
    ),
    swiftOut: 'ios/Classes/InlayNavigatorApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'InlayNavigatorError'),
    dartPackageName: 'inlay',
  ),
)
/// Describes a page to navigate to (Flutter or native).
///
/// [routeId] identifies the screen. [params] carries the page data
/// using pigeon's `encode()` output — the native side decodes it with
/// the matching pigeon-generated class's `fromList()` / `decode()`.
///
/// For Flutter pages pushed from native, [params] is a `Map<String, String>`
/// (produced by URL-decoding the `initialRoute` string).
class PageSettings {
  PageSettings({required this.routeId, this.params, this.path});

  /// Identifies which screen to show (e.g. "soundsNotifications").
  String routeId;

  /// Page parameters. For native pages this is the pigeon-encoded object
  /// (via `encode()`). For Flutter pages this is a `Map<String, String>`.
  Object? params;

  /// URL path derived from the typed route object (e.g. "/products/42").
  /// When set, used as the `initialRoute` for router-based navigation.
  String? path;
}

/// Host API — Flutter asks the platform to push a new Activity/ViewController.
///
/// The platform side owns the Activity/ViewController stack; Flutter cannot
/// start them directly. This API hides FlutterEngine / EngineGroup /
/// Activity/ViewController internals from the developer.
@HostApi()
abstract class InlayNavigatorHostApi {
  /// Push a new Flutter Activity/ViewController for the given page.
  void push(PageSettings page);

  /// Pop the current Flutter Activity/ViewController.
  void pop();

  /// Enable/disable native iOS back gesture for this container.
  ///
  /// Used by Flutter to disable container-level swipe-back while the in-Flutter
  /// navigator can handle pop, preventing double-pop.
  void setNativePopGestureEnabled(bool enabled);

  /// Open a native Activity/ViewController identified by [route].
  ///
  /// The platform side dispatches to a registered native route handler.
  /// If no handler is registered for the given `routeId`, this is a no-op
  /// (or throws, depending on platform configuration).
  void pushNativeRoute(PageSettings route);

  /// Return the full route data that the native host stored for this engine.
  ///
  /// Flutter calls this once at startup to retrieve the typed route object
  /// (with all fields, including complex nested objects). Returns `null`
  /// for the prewarm engine or when no data was set.
  PageSettings? getInitialRouteData();

  /// Present a Flutter dialog in a transparent native container.
  ///
  /// The native side creates a transparent Activity/ViewController and
  /// starts a new Flutter engine. Flutter renders the dialog content
  /// (barrier, animation, positioning) over the native screen underneath.
  void presentDialog(PageSettings page);
}
