import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/navigator/add2app_navigator.g.dart',
    kotlinOut: 'android/src/main/kotlin/co/leancode/add2app/navigator/Add2AppNavigatorApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'co.leancode.add2app.navigator',
    ),
    swiftOut: 'ios/Classes/Add2AppNavigatorApi.g.swift',
    dartPackageName: 'leancode_add2app',
  ),
)

/// Describes a Flutter page to navigate to.
///
/// On the Dart side developers create typed subclasses with named fields.
/// For transport over Pigeon, everything is flattened into [routeId] +
/// a string-keyed [params] map.
class PageSettings {
  PageSettings({required this.routeId, this.params});

  /// Identifies which screen to show (e.g. "soundsNotifications").
  String routeId;

  /// Immutable parameters for the page (e.g. {"contactId": "42"}).
  /// Nullable — pages with no parameters can omit this.
  Map<String, String>? params;
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
