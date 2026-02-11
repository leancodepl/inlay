import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/navigator/add2app_navigator.g.dart',
    kotlinOut:
        '../Signal-Android/app/src/main/java/co/leancode/signal_module/navigator/Add2AppNavigatorApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'co.leancode.signal_module.navigator',
    ),
    swiftOut: '../Signal-iOS/Signal/Flutter/Add2AppNavigatorApi.g.swift',
    dartPackageName: 'signal_module',
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

/// Host API — Flutter asks the platform to push a new Activity.
///
/// The platform side owns the Activity stack; Flutter cannot start
/// Activities directly.  This API hides FlutterEngine / EngineGroup /
/// Activity internals from the developer.
@HostApi()
abstract class Add2AppNavigatorHostApi {
  /// Push a new Flutter Activity for the given page.
  void push(PageSettings page);

  /// Pop the current Flutter Activity (finishes the Activity).
  void pop();
}
