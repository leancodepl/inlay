import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/navigator/add2app_navigator.g.dart',
    kotlinOut:
        'android/src/main/kotlin/co/leancode/add2app/navigator/Add2AppNavigatorApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'co.leancode.add2app.navigator',
      errorClassName: 'Add2AppNavigatorError',
    ),
    swiftOut: 'ios/Classes/Add2AppNavigatorApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'Add2AppNavigatorError'),
    dartPackageName: 'leancode_add2app',
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
abstract class Add2AppNavigatorHostApi {
  /// Push a new Flutter Activity/ViewController for the given page.
  void push(PageSettings page);

  /// Pop the current Flutter Activity/ViewController.
  void pop();

  /// Open a native Activity/ViewController identified by [route].
  ///
  /// The platform side dispatches to a registered native route handler.
  /// If no handler is registered for the given `routeId`, this is a no-op
  /// (or throws, depending on platform configuration).
  void pushNativeRoute(PageSettings route);
}
