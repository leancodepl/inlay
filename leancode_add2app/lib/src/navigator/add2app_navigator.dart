import 'package:flutter/widgets.dart';

import 'add2app_navigator.g.dart';

export 'add2app_navigator.g.dart' show PageSettings;

/// Route target understood by [Add2AppNavigator].
enum Add2AppRouteType { flutter, native }

/// Common abstraction for all pushable destinations.
abstract class Add2AppRoute {
  const Add2AppRoute();

  /// Whether this route should open Flutter or native UI.
  Add2AppRouteType get type;

  /// Convert destination to transport-level page settings.
  PageSettings toPageSettings();
}

/// A typed Flutter route description.
///
/// Developers extend this for each screen, adding typed immutable fields.
/// The framework serialises via [toPageSettings] so Pigeon only ever
/// transports the flat
/// `routeId + Map<String, String>` representation.
///
/// Example:
/// ```dart
/// class SoundsNotificationsPage extends Add2AppFlutterRoute {
///   const SoundsNotificationsPage({required this.contactId});
///   final String contactId;
///
///   @override
///   String get routeId => 'soundsNotifications';
///
///   @override
///   Map<String, String> get params => {'contactId': contactId};
/// }
/// ```
abstract class Add2AppFlutterRoute extends Add2AppRoute {
  const Add2AppFlutterRoute();

  /// Unique route identifier (matches the key in the page registry).
  String get routeId;

  /// Flat parameter map transported over Pigeon.
  Map<String, String> get params;

  @override
  Add2AppRouteType get type => Add2AppRouteType.flutter;

  /// Convert to the Pigeon-generated [PageSettings].
  PageSettings toPageSettings() {
    return PageSettings(routeId: routeId, params: params);
  }
}

/// Typed wrapper for native destinations.
///
/// Usually created by generated native page extensions, e.g.
/// `NativeEditProfilePage(...).toNativeRoute()`.
class Add2AppNativeRoute extends Add2AppRoute {
  const Add2AppNativeRoute(this.page);

  final PageSettings page;

  @override
  Add2AppRouteType get type => Add2AppRouteType.native;

  @override
  PageSettings toPageSettings() => page;
}

/// Signature for the factory that builds a [Widget] from the raw params map.
typedef PageBuilder = Widget Function(Map<String, String> params);

/// Framework-level navigator for add2app.
///
/// Hides all Flutter engine / Pigeon / platform-channel details from the
/// developer.  On the Dart side you just call:
///
/// ```dart
/// Add2AppNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
/// ```
///
/// For native pages, pass generated native `PageSettings`:
///
/// ```dart
/// Add2AppNavigator.instance.push(
///   NativeEditProfilePage(contactId: '42').toNativeRoute(),
/// );
/// ```
///
/// On the Android side:
/// ```kotlin
/// Add2AppNavigator.push(context, PageSettings("soundsNotifications", mapOf("contactId" to "42")))
/// ```
class Add2AppNavigator {
  Add2AppNavigator._();

  static final instance = Add2AppNavigator._();

  final _hostApi = Add2AppNavigatorHostApi();

  /// Registry: routeId → widget builder.
  final _pages = <String, PageBuilder>{};

  // ── Page registration ─────────────────────────────────────────────

  /// Register a page builder for a given [routeId].
  ///
  /// Call this once per page, typically in your entrypoint before `runApp`.
  void registerPage(String routeId, PageBuilder builder) {
    _pages[routeId] = builder;
  }

  /// Build a widget for the given [PageSettings].
  /// Returns an error widget if the route is not registered.
  Widget buildPage(PageSettings page) {
    final builder = _pages[page.routeId];
    if (builder == null) {
      return Center(child: Text('Unknown route: ${page.routeId}'));
    }
    final params = page.params;
    return builder(
      params is Map ? Map<String, String>.from(params) : <String, String>{},
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────

  /// Pushes either a Flutter route or a native route.
  Future<void> push(Add2AppRoute route) async {
    final page = route.toPageSettings();
    switch (route.type) {
      case Add2AppRouteType.flutter:
        await pushFlutterRoute(page);
        break;
      case Add2AppRouteType.native:
        await pushNativeRoute(page);
        break;
    }
  }

  /// Pop (finish) the current Flutter Activity/ViewController.
  Future<void> pop() async {
    await _hostApi.pop();
  }

  // ── Internal route dispatch ───────────────────────────────────────

  /// Internal method: push a Flutter Activity/ViewController route.
  Future<void> pushFlutterRoute(PageSettings page) async {
    await _hostApi.push(page);
  }

  /// Internal method: open a native Activity/ViewController route.
  ///
  /// The platform side dispatches to the `NativeRouteHandler` set via
  /// `Add2AppNavigator.setNativeRouteHandler(...)` on Android/iOS.
  ///
  /// Use the generated `.toNativeRoute()` extension on pigeon page classes:
  ///
  /// ```dart
  /// Add2AppNavigator.instance.push(
  ///   NativeEditProfilePage(contactId: '42').toNativeRoute(),
  /// );
  /// ```
  Future<void> pushNativeRoute(PageSettings page) async {
    await _hostApi.pushNativeRoute(page);
  }

  // ── Initial route parsing ─────────────────────────────────────────

  /// Decode the `initialRoute` string (set by the platform) back into
  /// [PageSettings].  Format: `routeId?key=val&key=val`
  static PageSettings decodeInitialRoute(String initialRoute) {
    final questionMark = initialRoute.indexOf('?');
    if (questionMark < 0) {
      return PageSettings(routeId: initialRoute);
    }

    final routeId = initialRoute.substring(0, questionMark);
    final query = initialRoute.substring(questionMark + 1);
    final params = <String, String>{};

    for (final pair in query.split('&')) {
      final eq = pair.indexOf('=');
      if (eq > 0) {
        params[Uri.decodeComponent(pair.substring(0, eq))] =
            Uri.decodeComponent(pair.substring(eq + 1));
      }
    }

    return PageSettings(routeId: routeId, params: params);
  }

  /// Reads platform `defaultRouteName` and decodes it into [PageSettings].
  ///
  /// Keeps Flutter platform-dispatcher details hidden from app modules.
  static PageSettings initialPageFromPlatform() {
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    return decodeInitialRoute(initialRoute);
  }
}
