import 'package:flutter/widgets.dart';

import 'add2app_navigator.g.dart';

export 'add2app_navigator.g.dart' show PageSettings;

/// A typed page description.
///
/// Developers extend this for each screen, adding typed immutable fields.
/// The framework serialises via [toPageSettings] so Pigeon only ever
/// transports the flat
/// `routeId + Map<String, String>` representation.
///
/// Example:
/// ```dart
/// class SoundsNotificationsPage extends Add2AppPage {
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
abstract class Add2AppPage {
  const Add2AppPage();

  /// Unique route identifier (matches the key in the page registry).
  String get routeId;

  /// Flat parameter map transported over Pigeon.
  Map<String, String> get params;

  /// Convert to the Pigeon-generated [PageSettings].
  PageSettings toPageSettings() {
    return PageSettings(routeId: routeId, params: params);
  }
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
    return builder(page.params ?? {});
  }

  // ── Navigation (Flutter → Flutter via platform) ─────────────────────

  /// Push a new Flutter Activity/ViewController for [page].
  Future<void> push(Add2AppPage page) async {
    await _hostApi.push(page.toPageSettings());
  }

  /// Pop (finish) the current Flutter Activity/ViewController.
  Future<void> pop() async {
    await _hostApi.pop();
  }

  // ── Navigation (Flutter → native) ─────────────────────────────────

  /// Open a native Activity/ViewController identified by [page].
  ///
  /// The platform side dispatches to a native route handler registered via
  /// `Add2AppNavigator.registerNativeRoute(...)` on Android/iOS.
  ///
  /// Example:
  /// ```dart
  /// Add2AppNavigator.instance.pushNativeRoute(
  ///   NativeSettingsPage(section: 'notifications'),
  /// );
  /// ```
  Future<void> pushNativeRoute(Add2AppPage page) async {
    await _hostApi.pushNativeRoute(page.toPageSettings());
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
}
